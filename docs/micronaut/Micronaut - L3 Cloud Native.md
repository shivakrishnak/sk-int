---
layout: default
title: "Micronaut - L3 Cloud Native"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 5
permalink: /micronaut/l3-cloud-native/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut Health Indicators and Management](#micronaut-health-indicators-and-management) | medium |
| 2 | [Micronaut Security and JWT](#micronaut-security-and-jwt) | high |
| 3 | [Micronaut Messaging Kafka and RabbitMQ](#micronaut-messaging-kafka-and-rabbitmq) | high |
| 4 | [Micronaut Function and AWS Lambda](#micronaut-function-and-aws-lambda) | high |
| 5 | [Micronaut Distributed Tracing](#micronaut-distributed-tracing) | medium |

---

# Micronaut Health Indicators and Management

**Interview Weight:** medium - Health endpoints are
table stakes for Kubernetes deployments. Tested for
liveness vs readiness and custom indicator implementation.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Management adds /health, /metrics, /info,
> and /env endpoints. The /health endpoint aggregates
> all registered health indicators. Two types matter
> for Kubernetes: liveness (is the app running) and
> readiness (is the app ready to serve traffic). Custom
> health indicators implement HealthIndicator and return
> HealthResult. Built-in: datasource connectivity,
> disk space, service discovery, custom indicators
> register automatically.

**3 minutes (Senior):**

> Health endpoint breakdown:
>
> GET /health:
>   Aggregates all HealthIndicator results.
>   Returns UP/DOWN/UNKNOWN.
>   200 for UP, 503 for DOWN.
>
> GET /health/liveness:
>   Is the JVM alive and not in a broken state.
>   Kubernetes liveness probe: restart on DOWN.
>   Should not include external dependencies
>   (DB, cache) - only internal app state.
>
> GET /health/readiness:
>   Can the app serve requests.
>   Kubernetes readiness probe: remove from LB on DOWN.
>   SHOULD include DB connectivity, cache health.
>   Start in DOWN, move to UP after init complete.
>
> Custom health indicator:
>   @Singleton
>   class DatabaseHealthIndicator
>       implements HealthIndicator {
>     Mono<HealthResult> getResult() { ... }
>   }
>
> Configuration:
>   endpoints.health.enabled: true
>   endpoints.health.details-visible: AUTHENTICATED
>   (hide details from public; visible when authenticated)
>
> Metrics (Micrometer):
>   micronaut-micrometer-core with registry
>   (prometheus, cloudwatch, datadog, etc.)
>   @Timed("order.create") on methods
>   inject MeterRegistry for custom metrics

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about health endpoints
in Micronaut - how to expose application health status."

**(2) First principles:** "Kubernetes needs to know if
your app is alive and ready. Health endpoints answer
those questions."

**(3) Bridge:** "Liveness = heartbeat. Readiness = ready
for traffic. Micronaut /health/liveness and /health/readiness
map directly to Kubernetes probe endpoints."

---

### 💻 Code Example

```java
// Custom health indicator
@Singleton
public class CacheHealthIndicator
        implements HealthIndicator {

    private final CacheManager cacheManager;

    CacheHealthIndicator(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    @Override
    public Publisher<HealthResult> getResult() {
        try {
            // Check cache connectivity
            cacheManager.getCache("orders")
                .get("__health_check__");

            return Publishers.just(
                HealthResult.builder("cache")
                    .status(HealthStatus.UP)
                    .details(Collections.singletonMap(
                        "status", "cache reachable"))
                    .build());
        } catch (Exception e) {
            return Publishers.just(
                HealthResult.builder("cache")
                    .status(HealthStatus.DOWN)
                    .details(Collections.singletonMap(
                        "error", e.getMessage()))
                    .build());
        }
    }
}

// application.yml
// micronaut:
//   application:
//     name: order-service
// endpoints:
//   health:
//     enabled: true
//     details-visible: AUTHENTICATED
//   metrics:
//     enabled: true
//     export:
//       prometheus:
//         enabled: true
//         step: PT1M

// Kubernetes probe configuration (k8s yaml)
// livenessProbe:
//   httpGet:
//     path: /health/liveness
//     port: 8080
//   initialDelaySeconds: 10
//   periodSeconds: 5
// readinessProbe:
//   httpGet:
//     path: /health/readiness
//     port: 8080
//   initialDelaySeconds: 5
//   periodSeconds: 3

// Custom metrics with Micrometer
@Singleton
public class OrderMetrics {

    private final Counter orderCreatedCounter;
    private final Timer orderProcessingTimer;

    OrderMetrics(MeterRegistry registry) {
        this.orderCreatedCounter = Counter
            .builder("orders.created")
            .description("Total orders created")
            .register(registry);

        this.orderProcessingTimer = Timer
            .builder("orders.processing.time")
            .description("Order processing duration")
            .register(registry);
    }

    public void recordOrderCreated() {
        orderCreatedCounter.increment();
    }

    public <T> T trackProcessing(
            Supplier<T> operation) {
        return orderProcessingTimer
            .record(operation);
    }
}
```

> **Code walkthrough:** CacheHealthIndicator returnsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a reactive Publisher<HealthResult>. If the cache check
> succeeds, returns HealthStatus.UP with details. On
> exception, DOWN with error message. Micronaut auto-discovers
> and registers any @Singleton HealthIndicator - no
> registration needed. The Kubernetes readiness probe
> at /health/readiness will include this indicator and
> route traffic away if the cache is down.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Management provides actuator-style endpoints for
health checks, metrics, and runtime information. The `management`
module exposes HTTP endpoints (`/health`, `/metrics`, `/info`,
`/env`) that enable Kubernetes probes, monitoring systems, and
observability tools.

**How it works:**

Add `micronaut-management` dependency. Default endpoints:
- `/health` - aggregated health status (UP/DOWN) from all
  registered `HealthIndicator` beans
- `/health/liveness` - Kubernetes liveness probe
- `/health/readiness` - Kubernetes readiness probe
- `/metrics` - Micrometer metrics (with `micronaut-micrometer-core`)
- `/info` - application metadata

Custom health indicators:
```java
@Singleton
class DatabaseHealthIndicator implements HealthIndicator {
    Publisher<HealthResult> getResult() {
        return Mono.fromCallable(() -> {
            checkDb();
            return HealthResult.builder("database").up().build();
        });
    }
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Kubernetes integration: configure liveness and readiness as
separate health groups with different indicator sets. Readiness
should check application-level dependencies (DB, downstream
services). Liveness should check only whether the app is
still functioning (not crashed).

**Why it matters:**

Kubernetes requires liveness and readiness probes for reliable
deployments. Production monitoring systems require health
endpoints. Separating liveness from readiness prevents healthy
pods from being restarted just because a downstream service
is temporarily unavailable.

---

### 🎓 Answers by Seniority

**Junior:** "@Singleton class implementing HealthIndicator
registers automatically. /health/liveness for liveness,
/health/readiness for readiness probes."

**Senior:** "Critical distinction: liveness should NOT
check DB or external services. If DB is down, the app
is still alive - just not ready. A liveness check that
includes DB will cause Kubernetes to restart the app
when the DB is down, making recovery impossible."

---

### ⚠️ Common Misconceptions

**Misconception 1: /health returning DOWN should always
cause Kubernetes to restart the pod.**

Only LIVENESS probe failures cause Kubernetes to restart a pod.
READINESS probe failures cause Kubernetes to stop sending
traffic to the pod (remove it from Service endpoints) without
restarting it. Confusing the two leads to: (1) configuring
downstream service health (DB, Redis) as liveness, causing pod
restarts when downstream is down (not the pod's fault), or
(2) configuring only liveness and not readiness, causing
traffic to unhealthy pods. Separate liveness (is the JVM
alive?) from readiness (are all dependencies available?).

**Misconception 2: Health endpoints are always safe to
expose publicly.**

Health endpoints that include detailed health information
(database connection details, internal service URLs, memory
stats, configuration values from `/env`) can expose sensitive
information. Restrict management endpoints to internal
networks: configure `endpoints.all.sensitive: true` to
require authentication; use a separate management port
(`endpoints.all.port: 8081`) not exposed outside the cluster;
configure Kubernetes probes to use the management port.

**Misconception 3: Custom HealthIndicators are always
called synchronously before responding to /health.**

Health indicators return `Publisher<HealthResult>`, enabling
parallel, async health checking. The default behavior: all
health indicators are invoked, their results are aggregated,
and the health response is returned when ALL complete.
A slow health indicator (e.g., waiting for a timeout from
an unreachable service) delays the /health response for ALL
callers. Configure `endpoints.health.discovery-client.enabled:
false` to exclude slow indicators from the health response;
add timeouts to custom health indicator reactive chains.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Kubernetes restarts healthy pods because
liveness probe checks downstream service availability.**

Symptom: pods are restarted during downstream outages
even though the pod itself is functioning correctly. Root
cause: liveness probe is configured to `/health` which
includes a database or external service health check
that returns DOWN when the downstream is unavailable.
Diagnosis: check which health indicators are in the
liveness health group vs readiness group. Fix: create
separate health groups: `micronaut.management.health.groups.
liveness.excludes: [database, downstream-service]`.
Liveness should only fail when the JVM is dead or the
app is in an unrecoverable state.

**Failure Mode 2: Health endpoint response time increases
under load because health checks run on request threads.**

Symptom: `/health` response time increases from 50ms to
5+ seconds during high load. Root cause: health indicators
performing DB queries or HTTP calls tie up request threads
or DB connections during health checks - the health check
competes with application requests for resources. Diagnosis:
monitor connection pool utilization during health checks.
Fix: use dedicated DB connections for health checks
(separate pool); use `@ExecuteOn(TaskExecutors.IO)` for
blocking health indicators; add caching to health indicators
(`@Cacheable` with short TTL) to avoid per-request checks.

**Failure Mode 3: /metrics endpoint returns empty data
after upgrading Micronaut version.**

Symptom: after upgrading, `/metrics` returns an empty JSON
object or 404. Root cause: Micronaut 4.x changed the default
Micrometer integration; `micronaut-micrometer-core` now
requires explicit inclusion. Diagnosis: check if `actuator`
metrics are registered by calling `/metrics` and checking
for `jvm.*` entries. Fix: add `io.micronaut.micrometer:
micronaut-micrometer-core` and at least one registry
(e.g., `micronaut-micrometer-registry-prometheus`) to
build dependencies; re-enable endpoints explicitly.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | /health endpoint, health indicators |
| Senior | 6 min | Liveness vs readiness, custom indicator, Micrometer |

---

**[SENIOR] Q1 - Why should liveness probes NOT
include database connectivity checks?**

*Why they ask:* Kubernetes probe misconfiguration is common.

If liveness probe checks DB:
- DB goes down (network blip, maintenance).
- /health/liveness returns DOWN.
- Kubernetes kills the pod (liveness failure).
- Pod restarts... DB still down.
- Pod immediately fails liveness again.
- Kubernetes keeps restarting pods.
- DB comes back up: all pods were killed, cold start
  required for all of them simultaneously.
- Thundering herd on DB reconnect.

Correct pattern:
- Liveness: check JVM, thread deadlocks, OOM.
  If these fail: restart is warranted.
- Readiness: check DB, cache, external APIs.
  If these fail: stop traffic but don't restart.
  App stays up to handle reconnect gracefully.

*What separates good from great:* Understanding the
restart cascade failure caused by DB in liveness.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Health indicators, /health endpoint. |
| Hiring Manager | Health checks = Kubernetes integration. |
| Bar Raiser | Liveness vs readiness semantics, restart cascade prevention. |
| Peer Engineer | "Removed DB check from liveness probe after a cascade restart event. Never again." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Security and JWT

**Interview Weight:** high - Security is tested in
every enterprise interview. JWT with Micronaut
Security is the production standard.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Security provides authentication via JWT,
> basic auth, LDAP, or OAuth2/OIDC. For JWT: configure
> the signing secret, set token expiry, enable
> micronaut.security.token.jwt. Methods or controllers
> protected with @Secured annotation. @Secured("isAuthenticated()")
> requires login. @Secured("ROLE_ADMIN") requires role.
> Token validated at the filter level - before the route
> handler runs.

**3 minutes (Senior):**

> JWT token flow:
>
> Login: POST /login with credentials.
>   LoginController (built-in) validates via
>   AuthenticationProvider.
>   Returns access_token (JWT) and refresh_token.
>
> Secured requests: include Authorization: Bearer {token}.
>   TokenValidator validates signature and expiry.
>   SecurityFilter runs before route handler.
>   Rejected with 401 if invalid.
>
> Authorization:
>   @Secured("isAuthenticated()") - any logged-in user
>   @Secured("ROLE_ADMIN") - requires ROLE_ADMIN
>   @Secured("hasRole('ADMIN') or hasRole('MANAGER')")
>   @Secured(SecurityRule.IS_ANONYMOUS) - public endpoint
>
> Custom AuthenticationProvider:
>   Implement authenticate(AuthenticationRequest)
>   Returns AuthenticationResponse.success(username, roles)
>     or AuthenticationResponse.failure(reason)
>   Supports LDAP, DB lookup, external IdP
>
> Token configuration:
>   micronaut.security.token.jwt.signatures.secret.generator.secret
>   micronaut.security.token.jwt.generator.access-token.expiration=3600
>   micronaut.security.token.jwt.generator.refresh-token.enabled=true
>
> OAuth2/OIDC:
>   micronaut-security-oauth2 dependency
>   Integrates with Google, GitHub, Keycloak, Auth0
>   Micronaut handles redirect, token exchange, user info

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about JWT authentication
in Micronaut - how to secure endpoints and validate tokens."

**(2) First principles:** "Auth = prove who you are.
JWT = proof encoded in a signed token. Filter = check
the proof before allowing access."

**(3) Bridge:** "Micronaut Security + JWT is Spring
Security + JWT but configured via YAML instead of a
SecurityConfig class. @Secured replaces @PreAuthorize."

---

### 💻 Code Example

```java
// Custom AuthenticationProvider
@Singleton
public class UserAuthenticationProvider
        implements AuthenticationProvider<HttpRequest<?>> {

    private final UserRepository userRepo;
    private final PasswordEncoder encoder;

    UserAuthenticationProvider(
            UserRepository userRepo,
            PasswordEncoder encoder) {
        this.userRepo = userRepo;
        this.encoder = encoder;
    }

    @Override
    public Publisher<AuthenticationResponse> authenticate(
            @Nullable HttpRequest<?> request,
            AuthenticationRequest<?,?> authReq) {

        String username =
            (String) authReq.getIdentity();
        String password =
            (String) authReq.getSecret();

        return userRepo.findByUsername(username)
            .map(user -> {
                if (!encoder.matches(
                        password, user.getPasswordHash())) {
                    return AuthenticationResponse
                        .failure(
                            AuthenticationFailureReason
                            .CREDENTIALS_DO_NOT_MATCH);
                }
                return AuthenticationResponse.success(
                    username,
                    user.getRoles(),
                    Collections.singletonMap(
                        "tenantId",
                        user.getTenantId()));
                // Claims added to JWT payload
            })
            .defaultIfEmpty(
                AuthenticationResponse.failure(
                    AuthenticationFailureReason
                    .USER_NOT_FOUND));
    }
}

// Protected controller
@Controller("/api/orders")
@Secured("isAuthenticated()")  // All methods require auth
public class OrderController {

    @Get("/{id}")
    public HttpResponse<OrderDto> findById(
            @PathVariable Long id,
            Authentication auth) {
        // auth.getName() = username from JWT
        // auth.getRoles() = roles from JWT
        String tenantId = (String) auth
            .getAttributes()
            .get("tenantId");
        return orderService.findByIdAndTenant(
            id, tenantId);
    }

    @Delete("/{id}")
    @Secured("ROLE_ADMIN")  // Override: admin only
    public HttpResponse<Void> delete(
            @PathVariable Long id) {
        orderService.delete(id);
        return HttpResponse.noContent();
    }
}

// Public endpoint: override class-level @Secured
@Controller("/api/public")
public class PublicController {

    @Get("/health")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public String health() {
        return "OK";
    }
}
```

> **Code walkthrough:** UserAuthenticationProvider.authenticate()ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> returns a reactive Publisher - non-blocking DB lookup.
> AuthenticationResponse.success() accepts extra claims
> (tenantId) that are embedded in the JWT payload.
> @Secured("isAuthenticated()") at class level means
> all methods require a valid JWT. @Secured("ROLE_ADMIN")
> on delete() overrides with a stricter rule. The
> Authentication parameter in handler methods is injected
> by Micronaut Security from the validated JWT claims.

---

### ⚠️ Common Misconceptions

**"Any secret works for JWT signing":**
The secret must be at least 256 bits (32 bytes) for
HS256. Short secrets are brute-forceable. Use a
cryptographically random secret, not a human-readable
password.

**"JWT expiry prevents token misuse after logout":**
JWT tokens are stateless - there's no server-side
revocation by default. After logout, the token remains
valid until expiry. For true revocation: use short
expiry (15 min) + refresh tokens, or maintain a
token revocation list (Redis).

---

### 🚨 Failure Modes and Diagnosis

**Symptoms and Fixes:**

1. 401 on valid JWT:
   - Cause: expired token, wrong signing secret,
     algorithm mismatch
   - Fix: verify token at jwt.io; check secret config
   - Debug: logging.level.io.micronaut.security=DEBUG

2. 403 despite correct role:
   - Cause: role stored as "ADMIN" but @Secured("ROLE_ADMIN")
   - Fix: ensure roles are stored/returned with "ROLE_" prefix
     OR use @Secured("ADMIN") without prefix

3. JWT secret in version control:
   - Security vulnerability
   - Fix: use ${JWT_SECRET} from environment variable
     micronaut.security.token.jwt.signatures.secret
     .generator.secret: ${JWT_SECRET}

---

### 📘 Concept Explanation

**What it is:**

Micronaut Security is a compile-time-aware security framework
for Micronaut applications. It provides authentication
(validating who you are), authorization (what you can do),
and JWT (JSON Web Token) support for stateless API security.

**How it works:**

JWT flow: client sends `Authorization: Bearer <token>` header.
Micronaut's `JwtTokenValidator` validates the signature using
the configured public key or JWKS endpoint. On valid token,
the claims are extracted and wrapped in an `Authentication`
object available to controllers via `@Nullable Authentication`.

Authorization: `@Secured("ROLE_ADMIN")` on controllers or
routes restricts access to principals with that role.
`@Secured(SecurityRule.IS_AUTHENTICATED)` requires any
authenticated user. Custom rules implement `SecurityRule`.

Token generation: for apps that issue JWTs, `JwtTokenGenerator`
creates signed tokens from a principal. Configure the signing
key and algorithm in `micronaut.security.token.jwt.*`.

**Why it matters:**

Stateless JWT authentication enables horizontal scaling
(no shared session store). Micronaut Security integrates
with compile-time validation (misconfigured routes detected
at build time). Native image support included.

---

### 🎓 Answers by Seniority

**Junior:** "@Secured on controllers/methods. Custom
AuthenticationProvider validates credentials. JWT
token returned on /login."

**Senior:** "JWT claims can include custom attributes
(tenantId, permissions) via the success() response.
These are embedded in the token and accessible via
Authentication.getAttributes(). Token revocation
requires short expiry + refresh token rotation."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | JWT flow, AuthenticationProvider, @Secured |
| Staff | 12 min | Token revocation, OAuth2/OIDC, security filter chain |

---

**[SENIOR] Q1 - How would you implement token
revocation in Micronaut JWT?**

*Why they ask:* Stateless JWT weakness in production.

Option 1: Short-lived tokens + refresh token rotation:
- Access token: 15 minute expiry
- Refresh token: 7 days, stored in Redis
- On logout: delete refresh token from Redis
- Attacker with stolen access token has max 15 min
  before it expires naturally

Option 2: Token blacklist in Redis:
```java
@Singleton
public class TokenRevocationService {

    private final RedisClient redis;

    public void revoke(String jti, long ttlSeconds) {
        // jti = JWT ID claim
        redis.set("revoked:" + jti, "1");
        redis.expire("revoked:" + jti, ttlSeconds);
    }
}

// Custom TokenValidator checks blacklist
@Singleton
@Replaces(JwtTokenValidator.class)
public class RevocationAwareValidator
        implements TokenValidator<HttpRequest<?>> {

    @Override
    public Publisher<Authentication> validateToken(
            String token,
            @Nullable HttpRequest<?> request) {

        String jti = extractJti(token);
        if (redis.exists("revoked:" + jti)) {
            return Publishers.empty();  // Rejected
        }
        return delegate.validateToken(
            token, request);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using authentication. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

This adds Redis as a dependency for every request
validation - latency tradeoff. For high-traffic APIs:
use short expiry (Option 1) to avoid the Redis lookup.

*What separates good from great:* Understanding the
stateless vs revocable trade-off and the Redis solution.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | JWT flow, @Secured, AuthenticationProvider. |
| Hiring Manager | Security for API endpoints. |
| Bar Raiser | Token revocation, custom claims, OAuth2/OIDC integration. |
| Peer Engineer | "Added jti claim and Redis blacklist. Logout works immediately. Redis adds ~2ms per request - acceptable." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Messaging Kafka and RabbitMQ

**Interview Weight:** high - Event-driven messaging
is central to microservices. Tested for producer/consumer
patterns, error handling, and ordering guarantees.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Kafka integration uses @KafkaClient for
> producers and @KafkaListener for consumers. Both
> are generated at compile time. Producers can be
> reactive (Single<RecordMetadata>) or blocking.
> Consumers can be reactive (subscribe to Flux) or
> batch. For RabbitMQ: @RabbitClient and @RabbitListener.
> Both support: manual acknowledgment, dead letter
> queues, exactly-once semantics (Kafka transactions).

**3 minutes (Senior):**

> Kafka producer patterns:
>
> @KafkaClient: interface with @Topic("orders")
>   send() methods return RecordMetadata or Single
>   @KafkaKey on parameter: sets Kafka message key
>     (key determines partition → ordering)
>
> Kafka consumer patterns:
>
> @KafkaListener(groupId="order-processor")
>   @Topic("orders") on method
>   Parameters: ConsumerRecord<K,V> or just value type
>   Offset management: auto-commit (default) or manual
>
> Manual offset commit (exactly-once):
>   @KafkaListener(offsetReset=EARLIEST)
>   Acknowledge parameter in listener method
>   Call ack.ack() after successful processing
>
> Error handling:
>   Default: log and skip on DeserializationException
>   Custom: ErrorHandlingDeserializer (DLQ routing)
>   @KafkaListener(errorStrategy=RETRY_ON_ERROR)
>
> Ordering guarantees:
>   Key-based: messages with same key → same partition
>   Same partition → ordered delivery
>   @KafkaKey Long orderId: all events for one order
>     delivered in order to one consumer
>
> Transactions (Kafka):
>   @KafkaClient(transactional=true)
>   Wraps send operations in Kafka transaction
>   Exactly-once: produce + consume in one txn

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kafka/RabbitMQ
integration in Micronaut - event-driven messaging."

**(2) First principles:** "Producer sends messages to
a topic/queue. Consumer reads and processes them.
Async communication between services."

**(3) Bridge:** "Micronaut @KafkaClient and @KafkaListener
are compile-time-generated Spring Kafka KafkaTemplate
and @KafkaListener equivalents."

---

### 💻 Code Example

```java
// Kafka Producer
@KafkaClient
public interface OrderEventProducer {

    @Topic("order-events")
    void send(
        @KafkaKey Long orderId,  // Key = partition key
        OrderEvent event);        // Value = message body

    // Reactive producer
    @Topic("order-events")
    Single<RecordMetadata> sendReactive(
        @KafkaKey Long orderId,
        OrderEvent event);

    // Explicit partition targeting
    @Topic("order-events")
    void sendToPartition(
        @KafkaKey Long orderId,
        int partition,
        OrderEvent event);
}

// Kafka Consumer
@KafkaListener(
    groupId = "order-processor",
    offsetReset = OffsetReset.EARLIEST)
public class OrderEventConsumer {

    private final OrderProcessingService service;

    OrderEventConsumer(
            OrderProcessingService service) {
        this.service = service;
    }

    @Topic("order-events")
    public void consume(
            ConsumerRecord<Long, OrderEvent> record,
            Acknowledgement ack) {
        try {
            Long orderId = record.key();
            OrderEvent event = record.value();

            log.info(
                "Processing event: {} for order: {}",
                event.getType(), orderId);

            service.process(orderId, event);

            // Manual commit after successful processing
            ack.ack();
        } catch (RetryableException e) {
            // Don't ack - message will be redelivered
            log.warn(
                "Retryable failure, will retry", e);
        } catch (PoisonPillException e) {
            // Ack anyway - send to DLQ separately
            dlqProducer.send(record);
            ack.ack();
        }
    }

    // Batch consumer for higher throughput
    @Topic("order-events")
    void consumeBatch(
            List<ConsumerRecord<Long, OrderEvent>>
                records,
            Acknowledgement ack) {
        records.forEach(record ->
            service.process(record.key(),
                           record.value()));
        ack.ack();  // Ack all in batch
    }
}

// RabbitMQ equivalent
@RabbitClient
public interface OrderRabbitProducer {
    @Binding("order.created")
    void send(OrderEvent event);
}

@RabbitListener
public class OrderRabbitConsumer {
    @Queue("order-processing-queue")
    void consume(
            OrderEvent event,
            Channel channel,
            @Header("deliveryTag") long tag)
            throws IOException {
        try {
            processOrder(event);
            channel.basicAck(tag, false);  // Ack
        } catch (Exception e) {
            channel.basicNack(
                tag, false, true);  // Requeue
        }
    }
}
```

> **Code walkthrough:** @KafkaKey Long orderId ensuresice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> all events for the same order go to the same partition,
> guaranteeing ordering. Manual Acknowledgement allows
> the consumer to control offset commits - only acknowledge
> after successful processing. RetryableException
> leaves the offset uncommitted (message redelivered).
> PoisonPillException routes to DLQ then acknowledges
> to avoid blocking the partition.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Messaging provides compile-time-safe integration
with message brokers: Apache Kafka (via `micronaut-kafka`)
and RabbitMQ (via `micronaut-rabbitmq`). Consumers and
producers are defined as annotated interfaces or methods,
with implementations generated at compile time.

**How it works:**

Kafka producer:
```java
@KafkaClient
interface OrderProducer {
    @Topic("orders")
    void send(@KafkaKey String orderId, Order order);
}
```

> **Code walkthrough:** The example above illustrates the core mechanism. The runtime processes the code in the sequence shown, applying the key pattern at each step. Misapplying this pattern results in subtle bugs or degraded performance. The takeaway: follow the structure shown to avoid the common pitfall.

Kafka consumer:
```java
@KafkaListener(groupId = "order-processor")
class OrderConsumer {
    @Topic("orders")
    void receive(Order order) { /* process */ }
}
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

Micronaut generates the producer implementation and configures
the consumer listener at compile time. No annotation scanning
at runtime.

RabbitMQ: similar pattern with `@RabbitClient` and
`@RabbitListener`. Declare exchanges/queues in configuration.

**Why it matters:**

Compile-time-generated messaging code is GraalVM native
compatible. Type-safe consumer definitions catch schema
mismatches at build time (with schema registry integration).

---

### 🎓 Answers by Seniority

**Junior:** "@KafkaClient interface for producers.
@KafkaListener for consumers. @Topic sets the topic name."

**Senior:** "@KafkaKey determines partitioning. Same key
→ same partition → ordered delivery. Manual acknowledgment
prevents data loss. DLQ routing for unprocessable messages.
Kafka transactions for exactly-once across produce + consume."

---

### ⚠️ Common Misconceptions

**Misconception 1: @KafkaListener methods consume messages
in the order they are produced.**

Order is only guaranteed WITHIN a partition. Kafka partitions
messages by key; messages with the same key go to the same
partition and are consumed in order by a single consumer.
Messages with different keys may go to different partitions,
processed by different consumer instances, with no ordering
guarantee. If end-to-end ordering matters, ensure all related
messages use the same key (e.g., order ID).

**Misconception 2: Setting acks=all on the Kafka producer
guarantees message delivery even if the broker fails.**

`acks=all` ensures the leader AND all in-sync replicas (ISR)
acknowledge the write. But if the broker fails AFTER the
acknowledgment and BEFORE the consumer processes the message,
the message can still be reprocessed. `acks=all` prevents
data loss at the broker level, not duplicate processing.
For exactly-once semantics, use Kafka transactions or
idempotent consumers with deduplication logic.

**Misconception 3: Micronaut Kafka consumers are
automatically parallel - multiple @KafkaListener methods
process the same topic concurrently.**

A single `@KafkaListener` group processes each partition
with ONE thread by default. Parallelism comes from: multiple
partitions (one consumer thread per partition), or multiple
consumer instances in the same group (up to one per partition).
Adding a second method `@Topic("orders")` in the same consumer
class does NOT add parallelism - it adds an additional consumer
that would receive the same messages (different group or config).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Consumer lag grows unbounded because
message processing is slower than production rate.**

Symptom: Kafka consumer lag metric increases continuously;
processed records count is lower than produced records count.
Root cause: the consumer processes one record at a time and
each record takes longer to process than the average production
interval. Diagnosis: compare producer throughput to consumer
throughput in Kafka metrics. Fix: increase consumer parallelism
(add partitions, add consumer instances); use `@KafkaListener`
with `threads = N` to enable parallel processing within a
consumer; offload processing to a thread pool if I/O-bound.

**Failure Mode 2: Deserialization errors cause consumer
to stop processing the entire partition.**

Symptom: consumer processes messages up to a point and then
stops; error log shows "Error deserializing key/value for
partition." Root cause: a malformed or schema-incompatible
message is at the consumer's current offset; deserialization
fails; the consumer cannot advance past this "poison pill."
Diagnosis: use a tool like `kafkacat` or Kafka console consumer
to read the raw bytes at the failing offset. Fix: configure
a `DeserializationExceptionHandler` to skip or dead-letter
malformed messages; use Micronaut's `ErrorStrategy.RETRY_ON_ERROR`
with a skip-after-N-retries policy.

**Failure Mode 3: Consumer group rebalance storm causes
processing gaps during deployments.**

Symptom: during rolling deployments, message processing
pauses for 30-60 seconds; consumer lag spikes during each
pod restart. Root cause: each new pod joining the consumer
group triggers a rebalance, which pauses all consumers
in the group until the rebalance completes. Fix: use
incremental cooperative rebalancing (Kafka 2.4+) by setting
`partition.assignment.strategy=CooperativeStickyAssignor`;
configure longer `session.timeout.ms` and `heartbeat.interval.ms`
to reduce false rebalances; use liveness probes that allow
sufficient time for the consumer to rejoin.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Partitioning, manual ack, DLQ, error handling |
| Staff | 12 min | Exactly-once, ordering guarantees, consumer group design |

---

**[SENIOR] Q1 - How do you ensure an order event
is not processed twice (exactly-once semantics)?**

*Why they ask:* Production correctness for payment/financial events.

Level 1: At-least-once + idempotent consumer:
- Kafka guarantees at-least-once delivery (default).
- Consumer may process the same message twice (crash
  after process but before ack).
- Fix: idempotent consumer using message key as
  deduplication key.

```java
@Topic("payment-events")
public void processPayment(
        ConsumerRecord<Long, PaymentEvent> record,
        Acknowledgement ack) {
    Long paymentId = record.key();

    // Check if already processed
    if (processedRepo.exists(paymentId)) {
        log.info("Duplicate: {}", paymentId);
        ack.ack();  // Skip, still ack
        return;
    }

    paymentService.apply(
        record.value());
    processedRepo.save(paymentId);  // Mark done
    ack.ack();
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Level 2: Kafka Transactions (exactly-once):
- Requires Kafka 0.11+.
- Producer in transactional mode.
- Consumer with isolation.level=read_committed.
- Consume-process-produce in one transaction.

```java
@KafkaClient(transactional = true)
public interface TransactionalProducer {
    @Topic("payment-processed")
    void send(@KafkaKey Long id, PaymentResult r);
}
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using Kafka messaging. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

For most cases: idempotent consumer (Level 1) is
simpler and sufficient. Use Kafka transactions only
when the processing itself is a Kafka produce.

*What separates good from great:* Distinguishing
idempotent consumer (simpler, most cases) from Kafka
transactions (complex, needed for consume-produce chains).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @KafkaClient, @KafkaListener, @Topic, @KafkaKey. |
| Hiring Manager | Event-driven microservices. |
| Bar Raiser | Exactly-once semantics, idempotent consumer vs Kafka transactions. |
| Peer Engineer | "Added processedEvent table as deduplication store. Payment double-processing incidents: zero since." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Function and AWS Lambda

**Interview Weight:** high - Serverless is a key
Micronaut use case. Tested for cold start optimization
and Function Bean pattern.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Functions implement the Function<I,O>
> interface and are annotated with @FunctionBean. For
> AWS Lambda: use micronaut-function-aws-api-proxy
> to handle API Gateway requests, or micronaut-function-aws
> for direct Lambda invocations. Micronaut's compile-time
> DI and small footprint mean cold start under 500ms
> for JVM, under 100ms for GraalVM native. No classpath
> scanning at cold start.

**3 minutes (Senior):**

> Function patterns:
>
> Simple function:
>   @FunctionBean("order-processor")
>   class OrderProcessor implements Function<Input, Output>
>   Handler: io.micronaut.function.aws.MicronautRequestHandler
>
> API Gateway proxy:
>   Extend MicronautLambdaHandler
>   Handles full HTTP request routing
>   Same @Controller code works locally AND on Lambda
>   micronaut-function-aws-api-proxy dependency
>
> Event sources:
>   SQS trigger: @SqsListener (micronaut-aws-sqs)
>   SNS: subscribe endpoint
>   DynamoDB streams: custom handler
>   S3 events: custom handler
>
> Cold start optimization:
>   Compile-time DI: no classpath scan (saves 200-800ms)
>   @Lazy on expensive beans: skip until first use
>   GraalVM native: <100ms total cold start
>   Provisioned concurrency: Lambda keeps warm instances
>
> Context object:
>   Inject io.micronaut.context.ApplicationContext
>   Inject any @Singleton bean normally
>   Context reuse between Lambda invocations
>     (ApplicationContext lives for container lifetime)
>
> Configuration:
>   application.yml read at runtime
>   AWS Secrets Manager/Parameter Store integration
>   Environment variables for secrets

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about running Micronaut
as an AWS Lambda function - serverless deployments."

**(2) First principles:** "Lambda = function that runs
on demand, charged per invocation, scales to zero.
Cold start = time to start the JVM and initialize
the app."

**(3) Bridge:** "Micronaut for Lambda is Spring Boot
for Lambda but 5-10x faster cold starts due to
compile-time DI."

---

### 💻 Code Example

```java
// Simple function bean
@FunctionBean("order-validator")
public class OrderValidatorFunction
        implements Function<
            OrderValidationRequest,
            OrderValidationResult> {

    private final OrderValidationService service;

    OrderValidatorFunction(
            OrderValidationService service) {
        this.service = service;
    }

    @Override
    public OrderValidationResult apply(
            OrderValidationRequest request) {
        return service.validate(request);
    }
}

// API Gateway proxy: same @Controller as local
@Controller("/orders")
public class OrderController {
    // Exact same code runs locally (HTTP server)
    // AND on Lambda via API Gateway proxy
    @Post
    public OrderDto create(
            @Valid @Body CreateOrderRequest req) {
        return orderService.create(req);
    }
}

// Lambda entry point for API Gateway proxy
public class LambdaHandler
        extends MicronautLambdaHandler {
    // That's it - MicronautLambdaHandler
    // routes API Gateway requests to @Controller
}

// SQS event consumer
@SqsListener(value = "order-processing-queue",
             visibilityTimeout = "30")
public class OrderQueueConsumer {

    private final OrderService service;

    @SqsMessage
    public void processMessage(
            OrderMessage message,
            SqsMessageContext ctx) {
        try {
            service.process(message);
            // Auto-delete on success
        } catch (Exception e) {
            ctx.fail();  // Returns to queue
        }
    }
}

// application.yml for Lambda
// micronaut:
//   application:
//     name: order-lambda
// aws:
//   lambda:
//     handler: io.example.LambdaHandler
//   secretsmanager:
//     enabled: true
//     prefix: /order-service/
//   parameterstore:
//     enabled: true
//     prefix: /order-service/config/
```

> **Code walkthrough:** @FunctionBean makes the classice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> discoverable as the Lambda handler. The same @Controller
> code works for both local HTTP server (integration
> tests, local dev) and Lambda API Gateway proxy.
> MicronautLambdaHandler routes the API Gateway event
> to the matching @Controller method. SQS listener
> uses automatic message deletion on success and
> ctx.fail() to return message to queue for retry.

---

### 📘 Concept Explanation

**What it is:**

Micronaut Functions is a programming model for creating
Java functions deployable to AWS Lambda, Azure Functions,
or Google Cloud Functions. The function is a standard
Micronaut application but packaged and initialized to
optimize for serverless cold starts.

**How it works:**

A Micronaut Lambda function:
1. Extends `MicronautRequestHandler<Input, Output>` (for
   AWS Lambda)
2. The first invocation starts the Micronaut context
   (200-500ms cold start on JVM; 10-50ms with native image)
3. Subsequent invocations reuse the warm context (~1-10ms)

Two deployment modes:
- **JVM + SnapStart**: standard JAR, Lambda snapshots the
  initialized state (virtual memory checkpoint) to reduce
  cold starts
- **GraalVM native**: compiled native executable, ~10-50ms
  cold start, no JIT warmup, suitable for latency-sensitive
  triggers

Lambda integration types: HTTP requests via API Gateway
(`APIGatewayProxyRequestEvent`), SQS events, SNS events,
direct Lambda invocations.

**Why it matters:**

Micronaut's compile-time DI and fast startup fit the
serverless model better than Spring Boot. For Lambda
functions called infrequently, sub-second cold starts
prevent timeout failures and improve user experience.

---

### 🎓 Answers by Seniority

**Junior:** "@FunctionBean on a Function<I,O> class.
Use MicronautLambdaHandler as the Lambda handler class."

**Senior:** "The key advantage: same @Controller code
runs locally (dev/test) and on Lambda (production).
No Lambda-specific API in your business logic. Cold
start is fast because compile-time DI skips classpath
scanning. For near-zero cold start: GraalVM native
image with micronaut-function-aws-native."

---

### ⚠️ Common Misconceptions

**Misconception 1: Lambda cold starts are always a
problem worth solving with native image.**

Cold starts matter for: synchronous API calls (user-facing,
low-latency requirements), low-invocation-frequency functions.
Cold starts do NOT matter for: asynchronous event processing
(SQS/SNS consumers), scheduled tasks, functions with
Provisioned Concurrency enabled. Native image compilation
is complex and has limitations (reflection, dynamic class
loading). Evaluate whether cold start is actually causing
problems before committing to the native image compilation
overhead.

**Misconception 2: GraalVM native Lambda functions have
the same behavior as JVM Lambda functions.**

Native image functions differ in: no JIT compilation (ahead-
of-time compiled, no warmup needed but also no JIT optimization
of hot paths), reflection and dynamic class loading must be
configured explicitly, different GC behavior (by default uses
Serial GC which is single-threaded), larger binary size (80-150MB
vs 50-100MB JAR), and build time 5-15 minutes. Thoroughly test
native builds with your specific libraries; not all third-party
libraries work without reflection configuration.

**Misconception 3: Micronaut Functions require AWS Lambda;
they cannot run locally.**

Micronaut Functions can be tested locally using
`FunctionTest` in unit tests (no Lambda infrastructure
needed), deployed to local AWS SAM CLI emulation
(`sam local invoke`), or run as a standalone HTTP service
(using `micronaut-function-web` for HTTP endpoint emulation).
The function code is standard Micronaut - the Lambda adapter
is a thin wrapper. Testing without Lambda infrastructure
is the recommended development workflow.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Lambda function times out on first
cold start but succeeds on subsequent invocations.**

Symptom: first Lambda invocation returns timeout error;
subsequent invocations complete within time limit. Root cause:
JVM cold start + Micronaut context initialization exceeds
the Lambda timeout (default 3-15 seconds). Diagnosis: check
Lambda CloudWatch logs for initialization duration. Fix:
increase Lambda timeout to accommodate cold start; enable
Lambda SnapStart (JVM checkpoint/restore); use GraalVM native
for sub-100ms starts; enable Provisioned Concurrency to
keep instances warm.

**Failure Mode 2: ClassNotFoundException in native Lambda
for classes used via reflection.**

Symptom: function works in JVM mode but throws
`ClassNotFoundException` or `InstantiationException` in
native mode. Root cause: a library or framework uses reflection
to load classes at runtime; GraalVM's static analysis did
not trace these classes. Diagnosis: run native build with
`-H:+TraceClassInitialization -H:+ReportExceptionStackTraces`.
Fix: add reflect-config.json entries for missing classes;
use Micronaut's `@ReflectiveAccess` annotation; run the
native-image agent to auto-generate configurations:
`java -agentlib:native-image-agent=config-output-dir=./config`.

**Failure Mode 3: Lambda function processes duplicate
SQS messages due to missing idempotency.**

Symptom: records appear duplicated in the database; events
are processed multiple times. Root cause: SQS guarantees
at-least-once delivery; Lambda may receive and process the
same message multiple times (network retry, Lambda execution
failure after partial processing). Diagnosis: add message ID
logging to verify duplicates. Fix: implement idempotent
processing: check if message ID was already processed
(DynamoDB with TTL-based idempotency key); design operations
to be safe to replay (upsert instead of insert, idempotent
state transitions).

---

### 🎯 Interview Deep-Dive

| Experience| Time| Depth|
|---|----------|---------------------------------------------------------------|
| Senior| 6 min| @FunctionBean, API Gateway proxy, cold start|
| Staff| 10 min| Native Lambda, cold start optimization, provisioned concurrency

---

**[SENIOR] Q1 - What is the ApplicationContext
lifecycle in Lambda and why does it matter?**

*Why they ask:* Lambda execution model affects performance.

Lambda container reuse:
1. First invocation: Lambda creates the container,
   JVM starts, Micronaut ApplicationContext initializes.
   This is the cold start. For Micronaut JVM: 300-800ms.
2. Subsequent invocations (warm): same container reused.
   ApplicationContext already initialized.
   Method runs in ~1ms overhead.
3. Container idle > ~15 min: terminated.
   Next invocation: cold start again.

Implication for @Singleton beans:
- Beans initialized at cold start persist across
  warm invocations.
- Database connections, HTTP client connections:
  kept open between invocations.
- Connection pool: sized appropriately for Lambda
  (max 1-2 connections per instance, not 10-20).

Memory state: @Singleton beans retain state between
invocations. Use @RequestScope (or reset state
explicitly) for per-invocation state.

Provisioned concurrency: AWS keeps N instances warm.
Eliminates cold starts. Cost: you pay for idle time.
Tradeoff: cold start latency vs cost.

*What separates good from great:* Container reuse
means Singleton state persists - must reset per-invocation
state explicitly.

| Interviewer Type| Emphasis|
|---|--------------------------------------------------------------------------|
| Technical Panel| @FunctionBean, Lambda handler, SQS integration.|
| Hiring Manager| Lambda for serverless microservices.|
| Bar Raiser| Cold start mechanics, container reuse, connection pool sizing.|
| Peer Engineer| "Lambda connection pool was sized at 10. Each instance hogged 1

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Distributed Tracing

**Interview Weight:** medium - Observability is required
for production microservices. Tested for tracing
propagation and integration.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut integrates with distributed tracing via
> OpenTelemetry (preferred) or Zipkin/Jaeger directly.
> Tracing is automatic for HTTP server and HTTP client:
> spans created per request, trace context propagated
> via W3C Trace Context headers. Custom spans: inject
> Tracer and create spans manually. Configure
> micronaut-tracing-opentelemetry with an exporter
> (Jaeger, Zipkin, OTLP for cloud).

**3 minutes (Senior):**

> Automatic instrumentation:
>
> HTTP Server: span per incoming request
>   Span attributes: method, URL, status code
>   Span name: HTTP GET /orders/{id}
>
> HTTP Client: span per outgoing call
>   Child span of incoming request span
>   Propagation: W3C traceparent header added automatically
>
> Data: spans for Micronaut Data queries
>   DB statement, duration, error
>
> Manual spans:
>   @NewSpan: creates a new span for the method
>   @SpanTag("param"): adds the method param as span tag
>   @ContinueSpan: adds to existing span without creating
>
> Configuration:
>   micronaut.tracing.opentelemetry.enabled: true
>   micronaut.tracing.opentelemetry.exporter.otlp.endpoint:
>     http://otel-collector:4317
>
> Log correlation:
>   Micronaut adds traceId and spanId to MDC.
>   Enables log → trace correlation in Grafana, Datadog.
>
> Baggage:
>   Propagate values across service boundaries.
>   tenantId in baggage: available in all downstream
>   services without explicit passing.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about distributed tracing
in Micronaut - tracking requests across multiple services."

**(2) First principles:** "Trace = the journey of one
request through multiple services. Span = one step
in that journey. Propagation = passing the trace ID
from service to service."

**(3) Bridge:** "Distributed tracing is the thread
that connects all the logs from service A to service B
to service C for a single request."

---

### 📘 Concept Explanation

**What it is:**

Micronaut Distributed Tracing enables end-to-end request
tracing across multiple microservices. It integrates with
OpenTelemetry, Zipkin, and Jaeger to propagate trace context,
record spans, and export trace data to observability backends.

**How it works:**

Micronaut automatically creates trace spans for:
- Incoming HTTP requests (server span)
- Outgoing HTTP requests via declarative clients (client span)
- Database operations (with JDBC/R2DBC integration)
- Kafka producer/consumer operations

Trace propagation: W3C Trace Context (`traceparent` header)
or B3 format. When Service A calls Service B via
`@Client`, the trace context headers are automatically
included in the outbound request. Service B's server filter
extracts and continues the trace.

Configuration:
```yaml
micronaut:
  tracing:
    opentelemetry:
      enabled: true
      exporter:
        otlp:
          endpoint: http://otel-collector:4318
```

> **Code walkthrough:** The example above illustrates the core mechanism. The runtime processes the code in the sequence shown, applying the key pattern at each step. Misapplying this pattern results in subtle bugs or degraded performance. The takeaway: follow the structure shown to avoid the common pitfall.

Custom spans:
```java
@NewSpan("process-order")
void processOrder(String orderId) { /* ... */ }
```

> **Code walkthrough:** This example illustrates the mechanism described above. The key operations execute in sequence, with each step building on the previous result. In production this pattern matters for correctness and observability. Misapplying it - such as omitting error handling or incorrect ordering - produces the failure mode described in the surrounding section. The takeaway: apply this pattern exactly as shown and verify the invariants hold under load.

**Why it matters:**

Distributed tracing reveals the performance breakdown across
service calls: which service is slow, which database query
takes too long, where errors originate. Essential for
diagnosing production issues in microservices architectures.

---

### 🎓 Answers by Seniority

**Junior:** "Add micronaut-tracing-opentelemetry.
Automatic spans for HTTP. @NewSpan for custom spans."

**Senior:** "W3C Trace Context propagation is automatic
for HTTP clients. Trace IDs in MDC enable log correlation.
For internal services: @NewSpan on service methods
creates child spans visible in Jaeger/Zipkin."

---

### ⚠️ Common Misconceptions

**Misconception 1: Adding Micronaut tracing automatically
traces all code execution without further configuration.**

Micronaut auto-instruments HTTP (in/out), JDBC, and Kafka
boundaries. It does NOT automatically trace: custom service
method calls, business logic steps, external SDK calls
(AWS SDK, email service), background tasks, or reactive
operators. For meaningful traces, annotate critical methods
with `@NewSpan` and add custom attributes with `@SpanTag`.
Without custom instrumentation, traces show network hops
but not the internal processing time breakdown.

**Misconception 2: Trace sampling at 100% is fine for
production systems.**

100% trace sampling means every request generates trace
data. For high-traffic services (thousands of RPS), this
can: overload the trace collector, add 5-20% request
latency overhead per traced request, generate massive data
storage costs. Use head-based sampling (1-10% for normal
traffic) with tail-based sampling (100% for errors and
slow requests) for production. Configure with OpenTelemetry
Collector's tail-based sampler.

**Misconception 3: TraceId is the same as CorrelationId
used in log messages.**

Trace ID and correlation ID serve different purposes and
often differ in format. Trace ID is W3C-standardized
(128-bit hex), used for distributed tracing. Correlation ID
may be any format, used for log correlation. Micronaut can
propagate trace ID as an MDC (Mapped Diagnostic Context)
variable for log correlation, making them the same value.
This requires explicit configuration in `logback.xml`
and the Micronaut tracing MDC integration.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Traces broken between services due
to trace context header mismatch.**

Symptom: Zipkin/Jaeger shows traces that terminate at
service boundaries - Service B shows independent root spans
instead of child spans of Service A's trace. Root cause:
Service A sends B3 headers (`X-B3-TraceId`); Service B
expects W3C headers (`traceparent`), or vice versa. Or the
HTTP client does not include propagation headers. Diagnosis:
inspect raw HTTP headers between services (`curl -v`);
check if `traceparent` or `X-B3-*` headers are present.
Fix: standardize on W3C Trace Context (B3 is legacy);
ensure both services use the same propagation format;
verify Micronaut client auto-propagation is enabled.

**Failure Mode 2: Custom @NewSpan spans not appearing
in traces despite annotation.**

Symptom: expected custom spans (from `@NewSpan` methods)
absent from trace. Root cause: `@NewSpan` is an AOP-based
annotation - if the method is called from within the same
class (bypassing the AOP proxy), no span is created. Also:
class must be a Micronaut-managed bean (not a plain class).
Diagnosis: verify the method is called through the Micronaut
proxy (via injection, not `this.method()`). Fix: ensure the
bean calling `@NewSpan` methods injects the bean and calls
via the injected reference, not via `this`.

**Failure Mode 3: Trace data overwhelms the collector
causing dropped spans during traffic spikes.**

Symptom: traces are incomplete - some spans missing;
collector shows "dropped spans" metrics. Root cause:
the OpenTelemetry collector is overloaded; batching
configuration sends too many spans per second. Diagnosis:
monitor collector queue depth and dropped span metrics.
Fix: increase collector resources; adjust SDK export
configuration (`maxExportBatchSize`, `exportIntervalMillis`);
enable tail-based sampling in the collector to reduce
volume; consider using an agent-based sampling approach
to drop low-value traces before they reach the collector.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Automatic instrumentation, @NewSpan, log correlation |
| Staff | 8 min | Sampling, baggage, OTLP, Grafana Tempo |

---

**[SENIOR] Q1 - How do you add tenantId to every
span without modifying every service method?**

*Why they ask:* Cross-cutting observability pattern.

Use OpenTelemetry Baggage:
```java
// In SecurityFilter: add tenant to trace baggage
@Filter("/**")
public class TenantTracingFilter
        implements HttpServerFilter {

    @Override
    public Publisher<MutableHttpResponse<?>> doFilter(
            HttpRequest<?> request,
            ServerFilterChain chain) {

        String tenantId = request
            .getHeaders().get("X-Tenant-Id");

        if (tenantId != null) {
            // Add to OpenTelemetry baggage
            // Propagated to all downstream calls
            Span.current().setAttribute(
                "tenant.id", tenantId);
            BaggageManager.current()
                .toBuilder()
                .put(BaggageEntry.create(
                    "tenant.id", tenantId))
                .build()
                .makeCurrent();
        }
        return chain.proceed(request);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using generic type. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

The tenantId attribute appears on every span
in the trace. Baggage propagation sends it in HTTP
headers to downstream services. All without modifying
individual service methods.

*What separates good from great:* Span attributes
vs baggage: attribute = this span only. Baggage =
propagates downstream.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @NewSpan, automatic HTTP spans, log correlation. |
| Hiring Manager | Observability = faster debugging. |
| Bar Raiser | Baggage propagation, span vs baggage distinction, MDC correlation. |
| Peer Engineer | "Added tenantId to all spans via filter. Debug time for tenant-specific issues went from 30 min to 2 min." |

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



