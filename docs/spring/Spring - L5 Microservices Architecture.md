---
layout: default
title: "Spring - L5 Microservices Architecture"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 14
permalink: /spring/l5-microservices-architecture/
---

# Spring - L5 Microservices Architecture

---

# Spring Microservices with Spring Cloud

---
id: SPR-026
title: Spring Microservices with Spring Cloud
category: Spring
difficulty: ★★★
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #spring-cloud, #microservices, #resilience, #distributed-systems
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — Spring Cloud is the de facto microservices toolkit
for Java. Senior/Staff interviews probe resilience patterns (circuit breaker,
retry), service communication, and distributed tracing.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Cloud provides a set of tools for building microservices: service
> discovery (Eureka or Kubernetes native), distributed configuration (Config Server),
> resilience (Resilience4j circuit breakers, retry), and inter-service communication
> (OpenFeign clients, RestTemplate/WebClient with load balancing). Spring Cloud
> Gateway is the API gateway. Spring Cloud Sleuth/Micrometer Tracing provides
> distributed tracing.

**3 minutes (Senior):**
> Spring Cloud solves the distributed systems challenges that Spring Boot alone
> doesn't address. Three categories:
>
> Communication: OpenFeign provides declarative HTTP client with load balancing,
> retry, and circuit breaker integration. WebClient with Spring Cloud LoadBalancer
> resolves service names to IPs from the service registry. In Kubernetes,
> the registry is Kubernetes DNS + Services (no Eureka needed).
>
> Resilience: Resilience4j provides circuit breaker (stop calling a failing
> service), rate limiter (protect yourself from overload), retry (transparent
> retries with backoff), and bulkhead (limit concurrency per dependency).
> @CircuitBreaker + @Retry annotations integrate with Spring AOP. Circuit breaker
> state: CLOSED (normal), OPEN (failing - reject calls), HALF_OPEN (probing if
> recovered).
>
> Observability: Micrometer Tracing (Spring Boot 3, replacing Sleuth) provides
> trace IDs propagated via HTTP headers (b3, traceparent). Each inter-service
> call carries the trace ID. Zipkin or Jaeger collects spans.

**Framework:** WHAT -> WHY -> HOW -> PRODUCTION -> FAILURE

*Adapting up:* Staff - service mesh vs Spring Cloud (where each belongs),
saga patterns for distributed transactions, event-driven vs synchronous
communication trade-offs, chaos engineering with Resilience4j.

*Adapting down:* Mid - "Spring Cloud adds tools to make microservices work
together: service discovery (how to find services), circuit breakers (how to
handle failures gracefully), and configuration servers (how to manage config
across services)."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Cloud - the toolkit for building
and running microservices with Spring Boot."

**(2) First principles:** "When you split a monolith into microservices, you get
distributed systems problems: services need to find each other, partial failures
need handling, config must be distributed, and requests span multiple services.
Spring Cloud solves each of these."

**(3) Bridge:** "Spring Cloud is the air traffic control system for microservices.
Service discovery is the radar. Circuit breakers are the no-fly zones. Config
server is the flight plan distribution system. Distributed tracing is the
flight recorder."

---

### 📘 Concept Explanation

**What it is:**
Spring Cloud is a collection of tools and frameworks that provide solutions
to common distributed systems patterns: service discovery, distributed configuration,
resilience, messaging, and observability for microservice architectures built
with Spring Boot.

**The problem it solves:**
Microservices introduce distributed systems complexity that doesn't exist in
monoliths: how do services find each other (discovery), how do services handle
downstream failures (resilience), how do you manage configuration across 50+
services (config management), and how do you trace a request across 10 hops
(observability)?

**How it works:**

```
Spring Cloud ecosystem map:

Service Communication:
  OpenFeign
    @FeignClient("order-service")
    interface OrderClient {
      @GetMapping("/orders/{id}")
      Order getOrder(@PathVariable Long id);
    }
    - Declarative HTTP client (like Spring MVC reversed)
    - Integrates with service registry
    - Retry and circuit breaker pluggable

  Spring Cloud LoadBalancer (replaces Ribbon)
    - Resolves "service-name" to list of instances
    - Load balancing strategies: round-robin, random
    - Works with Eureka, Consul, Kubernetes

Service Discovery:
  Eureka (Netflix OSS)
    - Services register themselves at startup
    - Clients discover services by name
    - Self-healing: deregisters unhealthy instances
    - Replicated cluster for HA

  Kubernetes Service + DNS (recommended for K8s)
    - No Eureka needed in K8s
    - kubernetes-discoveryClient uses K8s API
    - Service DNS: order-service.namespace.svc.cluster.local

Distributed Configuration:
  Spring Cloud Config Server
    - Central config server reads from Git/S3/Vault
    - Clients fetch config at startup
    - @RefreshScope: live config updates via /actuator/refresh
    - Bootstrap context loads config before ApplicationContext

Resilience (Resilience4j):
  Circuit Breaker:
    CLOSED -> OPEN -> HALF_OPEN -> CLOSED
    CLOSED: calls pass through, counting failures
    OPEN: calls rejected immediately (fast fail)
          (returns fallback)
    HALF_OPEN: limited calls probe recovery
    Config: failureRateThreshold=50% over 10 calls
            waitDurationInOpenState=30s

  Retry:
    @Retry(name="orderService",
           fallbackMethod="fallback")
    Automatic retry with exponential backoff
    Stops after maxAttempts (default 3)

  Rate Limiter:
    Limits calls per time window
    Protects downstream from request flood

  Bulkhead:
    Limits concurrent calls per service
    Prevents thread pool exhaustion

Spring Cloud Gateway:
  API Gateway pattern:
    All external traffic -> Gateway -> Services
    Routing rules based on path, headers
    Cross-cutting: auth, rate limiting, CORS
    Filters: pre-request (modify request) and
             post-request (modify response)

Distributed Tracing (Micrometer Tracing):
  TraceId: unique ID for entire request chain
  SpanId: unique ID per service hop
  Headers propagated: traceparent (W3C) or
                      X-B3-TraceId (Zipkin)
  Collection: Zipkin or Jaeger receives spans
  Visualization: trace timeline shows all hops
```

**The key insight:**
In Kubernetes deployments, many Spring Cloud components become redundant.
Kubernetes provides its own service discovery (DNS), load balancing (kube-proxy),
and can expose configuration via ConfigMaps. The Spring Cloud components that
remain valuable even in Kubernetes: Resilience4j (circuit breakers, retry),
Spring Cloud Gateway (API gateway, richer than Kubernetes Ingress), and
Micrometer Tracing (distributed tracing).

**When to use it:**
- Non-Kubernetes microservices: full Spring Cloud stack (Eureka, Config Server)
- Kubernetes microservices: Resilience4j, Spring Cloud Gateway, Micrometer Tracing
- Any microservices: circuit breakers for ALL inter-service calls

**When NOT to use it:**
- Monolith: Spring Cloud adds complexity without benefit
- Service mesh (Istio, Linkerd): circuit breakers and observability at
  infrastructure level; Spring Cloud Resilience4j may be redundant but
  provides application-level visibility that service mesh doesn't

---

### 💻 Code Example

```java
// OpenFeign client with resilience
@FeignClient(
    name = "inventory-service",
    fallbackFactory =
        InventoryClientFallbackFactory.class)
public interface InventoryClient {

    @GetMapping("/api/inventory/{productId}")
    @CircuitBreaker(name = "inventoryService")
    @Retry(name = "inventoryService")
    InventoryResponse getInventory(
        @PathVariable String productId);

    @PostMapping("/api/inventory/reserve")
    ReservationResponse reserve(
        @RequestBody ReservationRequest request);
}

// Fallback factory (provides fallback instances)
@Component
public class InventoryClientFallbackFactory
        implements FallbackFactory<InventoryClient> {

    @Override
    public InventoryClient create(Throwable cause) {
        return new InventoryClient() {
            @Override
            public InventoryResponse getInventory(
                    String productId) {
                log.warn("Inventory fallback for {}: {}",
                    productId, cause.getMessage());
                // Return degraded response (not null)
                return InventoryResponse.unavailable(
                    productId);
            }

            @Override
            public ReservationResponse reserve(
                    ReservationRequest req) {
                // Cannot reserve when inventory down
                throw new ServiceUnavailableException(
                    "Inventory service unavailable");
            }
        };
    }
}
```

> **Code walkthrough:** @FeignClient generates a Spring bean that makes HTTP calls
> to "inventory-service" (resolved via service registry or Kubernetes DNS).
> The FallbackFactory receives the cause exception, enabling context-aware fallbacks.
> The circuit breaker name maps to Resilience4j configuration. When the circuit is
> OPEN, Feign returns the fallback directly without making an HTTP call. The
> getInventory fallback returns a degraded response (not null, not exception) -
> the calling code can still function at reduced capacity.

```java
// Resilience4j configuration
// application.yml
resilience4j:
  circuitbreaker:
    instances:
      inventoryService:
        # Opens after 50% failure in last 10 calls
        failureRateThreshold: 50
        minimumNumberOfCalls: 10
        # Stays open 30 seconds before probing
        waitDurationInOpenState: 30s
        permittedNumberOfCallsInHalfOpenState: 5
        # What counts as failure
        recordExceptions:
          - java.io.IOException
          - feign.FeignException.ServiceUnavailable
        # What to ignore (not counted as failure)
        ignoreExceptions:
          - com.example.NotFoundException

  retry:
    instances:
      inventoryService:
        maxAttempts: 3
        waitDuration: 500ms
        # Exponential backoff: 500, 1000, 2000ms
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2
        retryExceptions:
          - java.io.IOException
        ignoreExceptions:
          - com.example.BadRequestException
```

```java
// Programmatic circuit breaker monitoring
@Service
public class InventoryService {

    private final CircuitBreakerRegistry registry;

    @EventListener
    public void onCircuitBreakerStateChange(
            CircuitBreakerOnStateTransitionEvent event) {
        log.warn("Circuit breaker [{}] state: {} -> {}",
            event.getCircuitBreakerName(),
            event.getStateTransition().getFromState(),
            event.getStateTransition().getToState());

        // Alert if circuit opens (service is failing)
        if (event.getStateTransition().getToState()
                == CircuitBreaker.State.OPEN) {
            alertingService.sendAlert(
                "Circuit breaker OPEN: "
                + event.getCircuitBreakerName());
        }
    }

    // Expose circuit breaker state as custom metric
    @PostConstruct
    public void registerMetrics() {
        CircuitBreaker cb = registry
            .circuitBreaker("inventoryService");
        TaggedCircuitBreakerMetrics
            .ofCircuitBreakerRegistry(registry)
            .bindTo(meterRegistry);
        // Creates metrics:
        // resilience4j.circuitbreaker.state (gauge)
        // resilience4j.circuitbreaker.calls (counter)
    }
}
```

> **Code walkthrough:** Resilience4j emits events for state transitions. Listening
> to CircuitBreakerOnStateTransitionEvent allows alerting when a circuit opens
> (indicating a failing downstream service). TaggedCircuitBreakerMetrics binds
> circuit breaker metrics to Micrometer - state (0=CLOSED, 1=OPEN, 2=HALF_OPEN)
> and call counts become Prometheus/Datadog metrics. This enables dashboards that
> show which inter-service dependencies are currently failing.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Cloud adds microservices features to Spring Boot. The main ones:
> Feign clients let you call other services with simple method calls (like
> calling a local service, but it makes HTTP calls). Circuit breakers prevent
> cascade failures - if service B is down, the circuit breaker stops service A
> from continuously retrying and making things worse. Spring Cloud Config Server
> centralizes configuration across services.

*Push deeper:* What is the difference between a retry and a circuit breaker?
When should you use each?

---

**Senior / Staff (5+ years):**
> Spring Cloud's most critical components for production: Resilience4j for
> circuit breakers and retry (mandatory on all inter-service calls), Spring Cloud
> Gateway for API routing with authentication and rate limiting, Micrometer Tracing
> for distributed tracing. In Kubernetes, Eureka is replaced by Kubernetes
> DNS/Services. Config Server is replaced by ConfigMaps/Secrets.
>
> Key design principle: circuit breaker state is per-service, not global.
> Inventory service circuit breaker opening should NOT affect payment service.
> Resilience4j instances are independently configured. Fallback behavior must
> be carefully designed: returning stale data vs. degraded response vs. error.
> The choice depends on the operation (read vs. write, critical vs. optional).

*Push deeper:* Saga patterns for distributed transactions: orchestration (central
coordinator) vs choreography (events between services). Spring doesn't provide
a saga framework, but Axon Framework and Eventuate do. The key challenge is
compensating transactions - what to undo when step 5 of a 10-step saga fails.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Retry and circuit breaker serve the same purpose."**
Retry handles transient failures (momentary network hiccup). Circuit breaker
handles sustained failures (service is down). Retry sends more requests -
the WRONG response to sustained failure. Using retry without circuit breaker
in a sustained failure scenario causes request amplification (100 original requests
* 3 retries = 300 requests to a failing service). Correct pattern: retry for
transient, circuit breaker for sustained, combined: retry while CLOSED, circuit
opens after sustained failure.

**Misconception 2: "Service discovery requires Eureka in Kubernetes."**
Kubernetes has built-in service discovery via DNS. Service "inventory-service"
is reachable at inventory-service.{namespace}.svc.cluster.local. Spring Cloud
Kubernetes discoveryClient uses the Kubernetes API for discovery. Eureka adds
no value in Kubernetes and adds operational complexity (running a Eureka cluster).

**Misconception 3: "A fallback should do everything the original does."**
Fallbacks should do the minimum needed to keep the calling service functional
in degraded mode. A complex fallback that queries multiple other services just
shifts the failure to another service. The best fallbacks: return cached data,
return a safe default, or return a clear "unavailable" indicator so the caller
can handle it.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Circuit breaker never opens**
Symptom: Downstream service is down, but requests keep retrying and failing.
Cause: Circuit breaker minimumNumberOfCalls not reached, or exception types
not in recordExceptions list (the failures are logged but not counted).
Diagnosis: Check Resilience4j actuator endpoint:
GET /actuator/circuitbreakers - shows current state and counters.
Check if exceptions thrown by Feign match recordExceptions.

**Failure 2: Cascade failure (all services fail)**
Symptom: One downstream service failure causes all upstream services to fail.
Cause: Thread pool exhaustion. Without bulkhead, waiting threads for
inventory-service exhaust the thread pool, starving payment-service requests.
Fix: Resilience4j Bulkhead limits concurrent calls per service.
Timeout configuration: Feign timeout + circuit breaker timeout must be shorter
than upstream service timeout.

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

#### Q1 - What is the circuit breaker pattern and how does Resilience4j implement it?

Circuit breaker is a resiliency pattern that prevents cascade failures by
stopping calls to a failing service:

States:
- CLOSED (normal): requests pass through; failure rate tracked
- OPEN (failing): requests rejected immediately without calling the service;
  fallback invoked; prevents request amplification and thread exhaustion
- HALF_OPEN (probing): limited test calls allowed to check if service recovered;
  if pass rate is sufficient -> CLOSED; if fail rate still high -> OPEN

Resilience4j implementation:
```java
@Service
public class OrderService {

    @CircuitBreaker(
        name = "inventoryService",
        fallbackMethod = "fallbackInventory")
    public InventoryResponse checkInventory(
            String productId) {
        return inventoryClient.check(productId);
    }

    // Fallback: same signature + Throwable
    public InventoryResponse fallbackInventory(
            String productId, Throwable t) {
        log.warn("Circuit breaker fallback "
            + "for product {}", productId);
        return InventoryResponse.assumeAvailable();
    }
}
```

Configuration (count-based window):
```yaml
resilience4j.circuitbreaker.instances
  .inventoryService:
  failureRateThreshold: 50
  minimumNumberOfCalls: 10
  waitDurationInOpenState: 30s
```

Configuration (time-based window):
```yaml
  slidingWindowType: TIME_BASED
  slidingWindowSize: 10  # 10 seconds window
  failureRateThreshold: 50
```

*What separates good from great:* The minimumNumberOfCalls threshold prevents
false-positive circuit opening during startup. If the first 2 calls fail (during
initialization), without a minimum threshold, the circuit would open. The
HALF_OPEN state is the recovery mechanism: limiting test calls to 5 prevents
flooding a recovering service while probing if it's healthy. permittedNumberOfCallsInHalfOpenState
should be much smaller than normal concurrency.

---

#### Q2 - How do you implement OpenFeign with load balancing and circuit breaker?

Full Feign setup:

```java
// Enable Feign
@SpringBootApplication
@EnableFeignClients
public class App { ... }

// Dependencies
dependencies {
    implementation("org.springframework.cloud"
        + ":spring-cloud-starter-openfeign")
    implementation("org.springframework.cloud"
        + ":spring-cloud-starter-loadbalancer")
    implementation("io.github.resilience4j"
        + ":resilience4j-spring-boot3")
}

// Feign client
@FeignClient(
    name = "inventory-service",  // service registry name
    configuration = FeignConfig.class)
public interface InventoryClient {
    @GetMapping("/inventory/{id}")
    Inventory get(@PathVariable Long id);
}

// Custom Feign config (per-client)
@Configuration
public class FeignConfig {

    @Bean
    public Retryer feignRetryer() {
        // Feign-level retry (before circuit breaker)
        return new Retryer.Default(
            100, 1000, 3);
    }

    @Bean
    public Request.Options requestOptions() {
        return new Request.Options(
            Duration.ofSeconds(2),  // connect timeout
            Duration.ofSeconds(5),  // read timeout
            true);  // follow redirects
    }
}
```

Load balancing: Spring Cloud LoadBalancer resolves "inventory-service" to
list of instances (from Eureka, Consul, or Kubernetes).
Default: round-robin. Custom: implement ReactorLoadBalancer.

*What separates good from great:* Feign has two levels of timeout that interact:
connectTimeout/readTimeout (HTTP level) and circuit breaker timeout (Resilience4j).
If readTimeout > circuit breaker's timeout, the HTTP call times out and triggers
the circuit breaker. If readTimeout < circuit breaker's timeout, the HTTP timeout
exception is what Resilience4j sees. Align them: set HTTP timeout shorter than
circuit breaker timeout so the circuit breaker measures HTTP timeouts correctly.

---

#### Q3 - What is Spring Cloud Gateway and how does it differ from Nginx?

Spring Cloud Gateway is a programmatic API gateway built on Spring WebFlux
(reactive, non-blocking):

Features:
- Route predicates: path, method, header, query param matching
- Filters: pre (modify request) and post (modify response)
- Built-in filters: auth, rate limiting, circuit breaker, retry, CORS
- Integration with Spring Security for authentication
- Reactive/non-blocking: high throughput for proxy workloads

```java
@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator routes(
            RouteLocatorBuilder builder) {
        return builder.routes()
            .route("order-route", r -> r
                .path("/api/orders/**")
                .filters(f -> f
                    .rewritePath("/api/orders/(?<rest>.*)",
                        "/orders/${rest}")
                    .addRequestHeader("X-Gateway", "true")
                    .circuitBreaker(config -> config
                        .setName("orders")
                        .setFallbackUri(
                            "forward:/fallback/orders"))
                    .requestRateLimiter(config -> config
                        .setRateLimiter(
                            redisRateLimiter())
                        .setKeyResolver(
                            userKeyResolver())))
                .uri("lb://order-service"))
            .build();
    }
}
```

vs Nginx:
- Nginx: static configuration (nginx.conf), high-performance C proxy
- Spring Cloud Gateway: dynamic Java configuration, Spring Security integration,
  Spring application (easier to customize), lower throughput than Nginx

When to use each:
- Spring Cloud Gateway: when you need custom auth logic, integration with
  Spring Security, dynamic routing from a database, or circuit breaker per route
- Nginx/Envoy: when maximum throughput is needed, or when a service mesh
  handles routing

*What separates good from great:* Spring Cloud Gateway runs as a Spring WebFlux
application. Its throughput is limited by the event loop threads (by default:
CPU cores * 2). For very high throughput (100K+ req/s), Nginx or Envoy are
more efficient. Spring Cloud Gateway's sweet spot: 10K-50K req/s with complex
routing logic that would require Nginx modules or Lua scripting.

---

#### Q4 - How does distributed tracing work with Micrometer Tracing?

Micrometer Tracing (Spring Boot 3+, replaces Spring Cloud Sleuth):

Concepts:
- Trace: end-to-end request across all services (unique TraceId)
- Span: work unit within a trace (unique SpanId, parent SpanId)
- Context propagation: trace headers passed between services

```
HTTP Request from browser:
  Service A receives request
    traceId = 1234abcd (new trace)
    spanId = 0001 (Service A span)
    |
    | Service A calls Service B
    | Header: traceparent: 00-1234abcd-0001-01
    v
  Service B receives request
    traceId = 1234abcd (same trace)
    spanId = 0002 (Service B span)
    parentSpanId = 0001 (Service A)
    |
    | Service B calls Service C
    | Header: traceparent: 00-1234abcd-0002-01
    v
  Service C receives request
    traceId = 1234abcd (same trace)
    spanId = 0003 (Service C span)

  All spans collected by Zipkin/Jaeger:
  Trace 1234abcd:
    [Service A: 0001, 100ms total]
      [Service B: 0002, 60ms total]
        [Service C: 0003, 20ms]
```

Spring Boot 3 setup:
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-brave</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.reporter2</groupId>
    <artifactId>zipkin-reporter-brave</artifactId>
</dependency>
```

```properties
management.tracing.sampling.probability=1.0  # 100% (dev)
management.tracing.sampling.probability=0.1  # 10% (prod)
spring.zipkin.base-url=http://zipkin:9411
```

*What separates good from great:* Sampling is critical for production tracing.
100% sampling = 1 trace record per request = significant overhead at scale.
10% sampling gives statistical representative traces. For debugging specific
issues: use header-based sampling (always trace requests with specific header).
OpenTelemetry (OTEL) is the CNCF-standard protocol - Micrometer Tracing
supports OTEL exporter, allowing export to Jaeger, Tempo, or any OTEL-compatible
backend.

---

#### Q5 - What is Spring Cloud Config Server and when is it needed?

Spring Cloud Config Server provides centralized externalized configuration:

Architecture:
```
Git Repository (or S3, Vault)
  application.yml
  application-prod.yml
  order-service.yml
  order-service-prod.yml
  |
  v
Config Server (Spring Boot app)
  Reads from Git at request time
  Exposes: GET /{application}/{profile}/{label}
  |
  v
Config Client (all microservices)
  Fetch config at startup from Config Server
  Merge with local application.properties
  Config Server values override local
```

Setup (Config Server):
```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/org/config-repo
          default-label: main
          search-paths: '{application}'
```

Setup (Config Client):
```properties
spring.config.import=configserver:http://config-server:8888
spring.application.name=order-service  # determines config file
spring.profiles.active=prod
```

Live refresh (@RefreshScope):
```java
@RestController
@RefreshScope  // Bean recreated on /actuator/refresh
public class FeatureController {
    @Value("${feature.new-checkout.enabled:false}")
    private boolean newCheckoutEnabled;
}
```
POST /actuator/refresh -> beans recreated with new config values.
Spring Cloud Bus: broadcast refresh to all instances via Kafka/RabbitMQ.

When to use:
- Non-Kubernetes: no ConfigMaps available
- Complex multi-service config with shared properties
- Need live config refresh without restarts

When Kubernetes ConfigMaps are sufficient:
- Config known at deployment time
- No runtime refresh needed
- Simpler operationally

*What separates good from great:* Spring Cloud Config Server supports
Vault integration: config values can be references to Vault paths.
`${vault.db.password}` is resolved by the Config Server's Vault backend,
never exposing the secret in plain text in Git. This is the recommended
pattern: structure in Git, secrets in Vault.

---

#### Q6 - How do you implement health-based service routing in Spring Cloud?

Load balancer health-aware routing ensures traffic only reaches healthy instances:

Kubernetes: handled natively. Pods failing readiness probes are removed from
Service endpoints. No additional Spring Cloud configuration needed.

With Eureka: health-aware routing requires configuration:
```yaml
eureka:
  client:
    healthcheck:
      enabled: true  # Use /actuator/health for Eureka status
```

Spring Cloud LoadBalancer with health filter:
```java
@Configuration
public class LoadBalancerConfig {

    @Bean
    @LoadBalancerClient(name = "inventory-service")
    public ReactorServiceInstanceLoadBalancer
            loadBalancer(Environment env,
                LoadBalancerClientFactory factory) {

        return new HealthCheckServiceInstanceListSupplier(
            factory.getLazyProvider(
                env.getProperty(
                    LoadBalancerClientFactory.PROPERTY_NAME),
                ServiceInstanceListSupplier.class),
            webClientBuilder.build());
    }
}
```

*What separates good from great:* The gap between Eureka deregistration and
load balancer cache update can cause brief routing to dead instances. Eureka's
cache TTL (default 30s) means a deregistered instance may still receive traffic
for 30 seconds. In Kubernetes, the same gap exists between endpoint table updates
and load balancer propagation. The solution: graceful shutdown (preStop hook + sleep
+ drain in-flight requests) ensures the old instance finishes requests before dying.

---

#### Q7 - How do you handle distributed transaction failures in microservices?

Distributed transactions (Saga pattern):

**Saga**: a sequence of local transactions, each publishing events or messages.
If any step fails, compensating transactions undo previous steps.

Types:

**Orchestration (central coordinator):**
```
OrderSaga (orchestrator):
  1. Create order (ORDER_DB) -> local TX
  2. Reserve inventory (HTTP to Inventory) -> local TX
  3. Charge payment (HTTP to Payment) -> local TX
  4. Confirm order (ORDER_DB) -> local TX

  If step 3 fails:
    Compensation: Cancel inventory reservation
    Compensation: Mark order as failed
```

**Choreography (event-driven):**
```
OrderCreated event
  -> InventoryService: reserve inventory
     -> InventoryReserved event
        -> PaymentService: charge payment
           -> PaymentCharged event
              -> OrderService: confirm order
  If any step fails:
    Service publishes failure event
    Previous services listen and compensate
```

Spring doesn't provide a saga framework, but:
- Axon Framework: orchestration sagas with @SagaOrchestrationStart
- Spring State Machine: model saga as state machine
- Manual: store saga state in DB with idempotent steps

*What separates good from great:* The hardest part of sagas is idempotency.
If step 3 (payment) succeeds but the response is lost (network failure),
the saga retries step 3. Payment is charged twice. Fix: idempotency key
in every step. Payment API: POST /payments with Idempotency-Key header.
Same key = same result. Store processed keys in Redis (TTL = max retry window).

---

#### Q8 - What is Spring Cloud Bus and how does it work?

Spring Cloud Bus links all instances of all services to a message broker (Kafka,
RabbitMQ). It enables broadcasting events across all service instances.

Use case: Config refresh broadcast
```
1. Config changed in Git
2. POST /actuator/busrefresh to one instance
3. That instance publishes RefreshRemoteApplicationEvent
   to the bus (Kafka topic or RabbitMQ exchange)
4. All other instances receive the event
5. Each instance calls its local /actuator/refresh
6. All @RefreshScope beans are recreated with new config
```

Alternative: Spring Cloud Config Monitor + webhook
```
Git webhook -> Config Server /monitor endpoint
-> Config Server publishes RefreshRemoteApplicationEvent
-> All instances refresh
```

Bus also enables:
- Custom event broadcasting between services
- Service state synchronization
- Dynamic log level changes across all instances

*What separates good from great:* Bus refresh is a blunt instrument: all instances
refresh simultaneously. In a high-traffic system, all instances pausing for
refresh at the same time causes a latency spike. Prefer Kubernetes ConfigMaps
rolling restart (gradual) over Bus refresh (simultaneous). If Bus refresh is
needed, add random jitter: each instance delays refresh by 0-5 seconds before
reloading.

---

#### Q9 - How do you implement rate limiting with Spring Cloud Gateway?

Spring Cloud Gateway's RequestRateLimiter filter:

```java
@Bean
public RouteLocator routes(
        RouteLocatorBuilder builder,
        RateLimiter rateLimiter) {
    return builder.routes()
        .route("api-rate-limited", r -> r
            .path("/api/**")
            .filters(f -> f
                .requestRateLimiter(c -> c
                    .setRateLimiter(rateLimiter)
                    .setKeyResolver(userKeyResolver())
                    .setStatusCode(
                        HttpStatus.TOO_MANY_REQUESTS)
                    .setDenyEmptyKey(false)
                    .setEmptyKeyStatus("ACCEPTED")))
            .uri("lb://api-service"))
        .build();
}

// Redis-backed rate limiter
@Bean
public RedisRateLimiter redisRateLimiter() {
    return new RedisRateLimiter(
        10,   // replenishRate: tokens/second
        20,   // burstCapacity: max tokens in bucket
        1);   // requestedTokens per request
}

// Rate limit by user ID from JWT
@Bean
public KeyResolver userKeyResolver() {
    return exchange -> exchange
        .getPrincipal()
        .map(Principal::getName)
        .switchIfEmpty(
            Mono.just("anonymous"));
}
```

Algorithm: Token bucket. replenishRate tokens added per second. burstCapacity is
the max tokens. Each request consumes tokens. No tokens -> 429 Too Many Requests.

Redis is required for distributed rate limiting. Without Redis, each gateway
instance has its own counter (ineffective for multi-instance gateway).

*What separates good from great:* Rate limiting at the gateway protects all
downstream services but is a coarse control. Service-level rate limiting (Resilience4j
RateLimiter) protects individual services. For per-user limits, Redis is the
correct backing store. For global service protection (prevent overload), combine:
gateway rate limit (per user) + service-level rate limit (total throughput).
The two are complementary, not redundant.

---

#### Q10 - What is the bulkhead pattern and how does it prevent cascade failures?

Bulkhead isolates failures to prevent one failing service from consuming all
resources and causing other services to fail:

Named after ship compartments: if one compartment floods, others stay dry.

Types in Resilience4j:

**Semaphore Bulkhead (concurrent calls limit):**
```yaml
resilience4j.bulkhead.instances
  .inventoryService:
  maxConcurrentCalls: 25
  maxWaitDuration: 500ms  # wait for slot
```
If 25 calls are concurrent to inventory-service, call 26 waits 500ms
then throws BulkheadFullException. Caller's fallback invoked.

**Thread Pool Bulkhead (isolated thread pools):**
```yaml
resilience4j.thread-pool-bulkhead.instances
  .inventoryService:
  maxThreadPoolSize: 4
  coreThreadPoolSize: 2
  queueCapacity: 25
```
Inventory-service calls run in a dedicated 4-thread pool.
Other services use the main thread pool (no contamination).

*What separates good from great:* Thread pool bulkhead is the stronger isolation
(truly separate thread pools). Semaphore bulkhead uses the caller's thread (faster
but less isolated). For truly independent service dependencies in production,
thread pool bulkhead prevents complete thread exhaustion: inventory thread pool
exhausts but payment thread pool is unaffected. The fallback method is called
on the calling thread, not the bulkhead pool.

---

#### Q11 - How does service-to-service authentication work in Spring Cloud?

Options:

**Option 1: JWT forwarding (user context):**
Each service forwards the user's JWT to downstream services.
All services validate the JWT against the same auth server.
User identity propagated through the chain.

**Option 2: Client credentials (service identity):**
Each service authenticates with the auth server using its own credentials.
Service-level access control (service A can call inventory, not payment).
Spring Cloud OpenFeign + spring-security-oauth2-client:
```java
@Bean
WebClient inventoryWebClient(
        OAuth2AuthorizedClientManager manager) {
    var filter = new
        ServletOAuth2AuthorizedClientExchangeFilterFunction(
            manager);
    filter.setDefaultClientRegistrationId(
        "inventory-service");
    return WebClient.builder()
        .apply(filter.oauth2Configuration())
        .build();
}
```

**Option 3: mTLS (mutual TLS):**
Each service presents a client certificate.
Service mesh (Istio) automates mTLS certificate rotation.
No application-level auth code needed.

*What separates good from great:* In practice: combine JWT forwarding
(user identity, for authorization) with service identity in additional headers
(for service-level audit). Some architectures use token exchange (RFC 8693):
the calling service exchanges the user JWT for a service-scoped JWT that carries
the user's sub but scopes for the specific downstream service. This is the most
secure pattern but requires an authorization server that supports token exchange.

---

#### Q12 - What are the trade-offs between synchronous and asynchronous communication in microservices?

**Synchronous (REST/gRPC):**
- Caller waits for response
- Simple to implement (Feign client is straightforward)
- Strong consistency: immediate confirmation
- Tight temporal coupling: both services must be available simultaneously
- Cascade failures: chain failure propagates synchronously

**Asynchronous (Kafka/RabbitMQ):**
- Caller publishes message, does not wait
- Producer decoupled from consumer (temporal decoupling)
- Higher complexity: message schemas, consumer error handling
- Eventual consistency: consumer may lag
- Natural buffer: messages accumulate during consumer downtime
- Better fault isolation: producer works even if consumer is down

When to use each:

Synchronous:
- Need immediate response (user waiting)
- Simple request-response semantics
- Both services typically available

Asynchronous:
- Long-running operations (email, report generation)
- High-volume event streams
- Multiple consumers of same event
- Consumer can batch process for efficiency

Hybrid pattern (request-reply asynchronous):
1. Service A publishes command to queue
2. Service A polls for result (or uses webhook callback)
3. Service B processes and publishes result
4. Service A receives result

Spring Cloud Stream: abstracts Kafka/RabbitMQ with consistent programming model.
@EnableBinding, @StreamListener (Spring Cloud Stream 3.x).
Spring Cloud Stream 4.x: functional style with Consumer<T>, Function<T,R> beans.

*What separates good from great:* The outbox pattern prevents data inconsistency
at the boundary between synchronous and asynchronous. When Service A saves
an order AND publishes an event, these are two different systems. If the DB
transaction succeeds but Kafka publish fails: inconsistency. Outbox: save the
event TO THE SAME DATABASE TABLE as the order (in the same transaction). A
separate poller reads the outbox and publishes to Kafka. This ensures exactly-once
semantics at the cost of increased latency (poll interval).
