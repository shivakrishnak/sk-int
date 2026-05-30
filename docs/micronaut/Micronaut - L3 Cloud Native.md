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

> **Code walkthrough:** CacheHealthIndicator returns
> a reactive Publisher<HealthResult>. If the cache check
> succeeds, returns HealthStatus.UP with details. On
> exception, DOWN with error message. Micronaut auto-discovers
> and registers any @Singleton HealthIndicator - no
> registration needed. The Kubernetes readiness probe
> at /health/readiness will include this indicator and
> route traffic away if the cache is down.

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

> **Code walkthrough:** UserAuthenticationProvider.authenticate()
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

> **Code walkthrough:** @KafkaKey Long orderId ensures
> all events for the same order go to the same partition,
> guaranteeing ordering. Manual Acknowledgement allows
> the consumer to control offset commits - only acknowledge
> after successful processing. RetryableException
> leaves the offset uncommitted (message redelivered).
> PoisonPillException routes to DLQ then acknowledges
> to avoid blocking the partition.

---

### 🎓 Answers by Seniority

**Junior:** "@KafkaClient interface for producers.
@KafkaListener for consumers. @Topic sets the topic name."

**Senior:** "@KafkaKey determines partitioning. Same key
→ same partition → ordered delivery. Manual acknowledgment
prevents data loss. DLQ routing for unprocessable messages.
Kafka transactions for exactly-once across produce + consume."

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

> **Code walkthrough:** @FunctionBean makes the class
> discoverable as the Lambda handler. The same @Controller
> code works for both local HTTP server (integration
> tests, local dev) and Lambda API Gateway proxy.
> MicronautLambdaHandler routes the API Gateway event
> to the matching @Controller method. SQS listener
> uses automatic message deletion on success and
> ctx.fail() to return message to queue for retry.

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

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | @FunctionBean, API Gateway proxy, cold start |
| Staff | 10 min | Native Lambda, cold start optimization, provisioned concurrency |

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

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @FunctionBean, Lambda handler, SQS integration. |
| Hiring Manager | Lambda for serverless microservices. |
| Bar Raiser | Cold start mechanics, container reuse, connection pool sizing. |
| Peer Engineer | "Lambda connection pool was sized at 10. Each instance hogged 10 connections. RDS hit max connections. Reduced to 2 per Lambda instance." |

---

---

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

### 🎓 Answers by Seniority

**Junior:** "Add micronaut-tracing-opentelemetry.
Automatic spans for HTTP. @NewSpan for custom spans."

**Senior:** "W3C Trace Context propagation is automatic
for HTTP clients. Trace IDs in MDC enable log correlation.
For internal services: @NewSpan on service methods
creates child spans visible in Jaeger/Zipkin."

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
