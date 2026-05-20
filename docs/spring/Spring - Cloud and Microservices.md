---
layout: default
title: "Spring - Cloud and Microservices"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 10
permalink: /interview/spring/cloud-and-microservices/
topic: Spring
subtopic: Cloud and Microservices
keywords:
  - Service Discovery and Load Balancing
  - API Gateway with Spring Cloud Gateway
  - Circuit Breaker with Resilience4j
  - Distributed Configuration
  - Observability with Micrometer and Tracing
difficulty_range: hard to expert
status: complete
version: 3
---

**Keywords covered in this file:**

- [Service Discovery and Load Balancing](#service-discovery-and-load-balancing)
- [API Gateway with Spring Cloud Gateway](#api-gateway-with-spring-cloud-gateway)
- [Circuit Breaker with Resilience4j](#circuit-breaker-with-resilience4j)
- [Distributed Configuration](#distributed-configuration)
- [Observability with Micrometer and Tracing](#observability-with-micrometer-and-tracing)

# Service Discovery and Load Balancing

**TL;DR** - Service discovery (Eureka, Consul, Kubernetes DNS) lets microservices find each other by name instead of hardcoded URLs, while client-side load balancing (Spring Cloud LoadBalancer) distributes requests across instances - enabling dynamic scaling without configuration changes.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Service A calls Service B at `http://10.0.1.5:8080`. Service B scales to 3 instances. Someone manually updates A's config with all 3 IPs. Instance 2 crashes. A still routes traffic to it. Manual IP management for 50 services with 200 instances is impossible.

**THE BREAKING POINT:**
Auto-scaling adds 5 new instances of the payment service. The order service does not know they exist. Load is still on the original 3 instances.

**THE INVENTION MOMENT:**
"This is exactly why Service Discovery was created."

---

### 📘 Textbook Definition

Service discovery is a pattern where services register themselves with a registry (Eureka, Consul) and discover other services by name. The client queries the registry, gets a list of healthy instances, and uses client-side load balancing to select one. Spring Cloud LoadBalancer (replacing Ribbon) provides `@LoadBalanced RestTemplate` or `ReactorLoadBalancerExchangeFilterFunction` for WebClient. In Kubernetes, DNS-based service discovery replaces the registry.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Services register their address; other services look up by name. No hardcoded URLs. Auto-scaling just works.

**One analogy:**

> A phone directory. Instead of memorizing phone numbers (IPs), you look up "Pizza Place" (service name) in the directory (registry). If a new Pizza Place opens (new instance), it is automatically listed. If one closes (instance down), it is removed. You always get a valid number.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use (junior):**

Eureka setup:

```yaml
# Service registration
spring:
  application:
    name: order-service
eureka:
  client:
    service-url:
      defaultZone: http://eureka:8761
        /eureka/
```

```java
// Client-side load balancing
@Bean
@LoadBalanced
public RestTemplate restTemplate() {
    return new RestTemplate();
}

// Call by service name, not URL
restTemplate.getForObject(
    "http://payment-service/pay",
    Payment.class);
// LoadBalancer resolves
// "payment-service" to an instance
```

**Level 3 - How it works (mid-level):**

```
  Service startup:
  payment-service registers with Eureka
  (host, port, health endpoint)
       |
  Eureka maintains registry:
    payment-service:
      - 10.0.1.5:8080 (UP)
      - 10.0.1.6:8080 (UP)
      - 10.0.1.7:8080 (UP)
       |
  order-service calls:
  http://payment-service/pay
       |
  @LoadBalanced intercepts:
    1. Query Eureka for
       "payment-service"
    2. Get list of instances
    3. Round-robin select one
    4. Replace URL with real IP:port
       |
  Actual call: http://10.0.1.6:8080/pay
```

**Level 4 - Mastery (senior/staff+):**

Eureka vs Kubernetes discovery:

| Feature        | Eureka           | Kubernetes                |
| -------------- | ---------------- | ------------------------- |
| Registry       | Eureka Server    | kube-dns / CoreDNS        |
| Registration   | Client registers | Pod auto-registered       |
| Health         | Client heartbeat | Liveness/readiness probes |
| Load balancing | Client-side      | kube-proxy (server-side)  |
| Extra infra    | Eureka server    | None (built into K8s)     |

Spring Cloud Kubernetes:

```yaml
spring:
  cloud:
    kubernetes:
      discovery:
        enabled: true
        all-namespaces: false
# Uses Kubernetes API for discovery
# No Eureka needed
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Eureka for service discovery."

**A Staff says:** "In Kubernetes, I skip Eureka entirely - K8s provides DNS-based discovery and server-side load balancing. For non-K8s environments, I use Eureka with client-side load balancing. I configure health checks, graceful shutdown (deregister before stopping), and zone-aware routing for multi-AZ deployments."

---

### 📌 Quick Reference Card

**WHAT IT IS:** Services register and discover each other by name, with automatic load balancing.

**KEY INSIGHT:** In Kubernetes, built-in DNS replaces Eureka. No extra infrastructure needed.

**ANTI-PATTERN:** Hardcoded service URLs. Running Eureka in Kubernetes (redundant).

**ONE-LINER:** "Register by name, discover by name, load-balance automatically."

**If you remember only 3 things:**

1. Services register, clients discover by name (not IP)
2. @LoadBalanced RestTemplate resolves service names
3. In Kubernetes, use K8s DNS instead of Eureka

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does service discovery work in Spring Cloud?**

**Answer:**
Service registers with Eureka (name, host, port). Clients use `@LoadBalanced RestTemplate` - the load balancer intercepts calls by service name, queries Eureka for instances, selects one (round-robin), and routes the request. Health checks remove failed instances from the registry.

In Kubernetes: DNS resolves service names to cluster IPs. `kube-proxy` handles load balancing. No Eureka needed.

---

### 🔗 Related Keywords

**Prerequisites:** Microservices Architecture, HTTP

**Builds on:** API Gateway, Circuit Breaker

**Alternatives:** Consul, Kubernetes DNS, HashiCorp Nomad

---

---

# API Gateway with Spring Cloud Gateway

**TL;DR** - Spring Cloud Gateway is a reactive API gateway that provides a single entry point for all microservices - handling routing, rate limiting, authentication, request/response transformation, and load balancing through a declarative route configuration.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Clients call 15 different microservices directly. Each service handles its own authentication, rate limiting, and CORS. The mobile app needs to know 15 service URLs. Adding a new service requires updating all clients.

**THE BREAKING POINT:**
The frontend team asks: "Which of the 15 services handles user profiles? What is its URL? How does its authentication work?" Meanwhile, DDoS traffic hits all 15 services because there is no central rate limiting.

---

### 📘 Textbook Definition

Spring Cloud Gateway (SCG) is a reactive API gateway built on Spring WebFlux and Project Reactor. It routes requests to downstream services based on predicates (path, header, method), applies filters (authentication, rate limiting, request rewriting), and integrates with service discovery for dynamic routing. Configuration is declarative via YAML or Java DSL. It replaces the deprecated Netflix Zuul.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
A single entry point that routes `/api/users/**` to user-service and `/api/orders/**` to order-service, with cross-cutting concerns applied centrally.

**One analogy:**

> A hotel concierge. Guests (clients) ask the concierge (gateway) for anything. The concierge routes to the right department (service): housekeeping, restaurant, spa. The concierge also handles security (authentication), manages waiting times (rate limiting), and translates requests (transformation). Guests never interact with departments directly.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
          filters:
            - StripPrefix=1

        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/orders/**
          filters:
            - StripPrefix=1
```

`lb://` = load-balanced via service discovery. `/api/users/42` -> user-service `/users/42`.

**Level 3 - How it works (mid-level):**

```
  Client: GET /api/users/42
       |
  Gateway receives request
       |
  Route matching:
    Check predicates in order
    /api/users/** matches user-service
       |
  Pre-filters execute:
    Authentication filter
    Rate limiting filter
    StripPrefix removes /api
       |
  Forward to user-service:
    lb://user-service/users/42
    LoadBalancer selects instance
       |
  user-service responds
       |
  Post-filters execute:
    Add response headers
    Logging
       |
  Response to client
```

**Level 4 - Mastery (senior/staff+):**

Custom global filter:

```java
@Component
public class AuthFilter
        implements GlobalFilter, Ordered {

    public Mono<Void> filter(
            ServerWebExchange exchange,
            GatewayFilterChain chain) {
        String token = exchange
            .getRequest().getHeaders()
            .getFirst("Authorization");
        if (token == null
                || !tokenService
                    .isValid(token)) {
            exchange.getResponse()
                .setStatusCode(
                    UNAUTHORIZED);
            return exchange.getResponse()
                .setComplete();
        }
        return chain.filter(exchange);
    }

    public int getOrder() { return -1; }
}
```

Rate limiting with Redis:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: api
          uri: lb://api-service
          predicates:
            - Path=/api/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter:
                  replenishRate: 100
                  burstCapacity: 200
                key-resolver: "#{@ipKeyResolver}"
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Spring Cloud Gateway for routing."

**A Staff says:** "I design the gateway as a thin routing layer - no business logic. Authentication is delegated to an OAuth2 provider. Rate limiting uses Redis for distributed state. I separate gateway concerns (routing, auth, rate limiting) from service concerns (business logic). Circuit breakers on gateway routes prevent cascading failures."

---

### 📌 Quick Reference Card

**WHAT IT IS:** Reactive API gateway for routing, filtering, and cross-cutting concerns.

**KEY INSIGHT:** Single entry point. Thin layer. No business logic in gateway.

**ANTI-PATTERN:** Business logic in gateway filters. Gateway as a monolith.

**ONE-LINER:** "Route by path, filter centrally, balance load automatically."

**If you remember only 3 things:**

1. Routes = predicate (match) + filters (transform) + URI (target)
2. `lb://service-name` for load-balanced routing via discovery
3. Global filters for auth, rate limiting, logging - applied to all routes

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: What is Spring Cloud Gateway and why use it?**

**Answer:**
Single entry point for all microservices. Routes requests by path/header to downstream services. Applies cross-cutting concerns centrally: authentication, rate limiting, CORS, logging. Built on WebFlux (reactive, non-blocking). Integrates with service discovery (`lb://` prefix).

Benefits: clients know one URL. Centralized security. Easy to add/remove services. Rate limiting at the edge.

---

### 🔗 Related Keywords

**Prerequisites:** Service Discovery, Spring WebFlux

**Builds on:** Circuit Breaker, OAuth2

**Alternatives:** Kong, Envoy, AWS API Gateway, Netflix Zuul (deprecated)

---

---

# Circuit Breaker with Resilience4j

**TL;DR** - Resilience4j's circuit breaker monitors failure rates of downstream calls and "trips" (opens) when failures exceed a threshold - stopping requests to a failing service, allowing it to recover, and providing fallback responses instead of cascading failures.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Service A calls Service B. Service B is slow (5-second timeout). Service A has 100 threads, all waiting for B. A's thread pool is exhausted. A cannot serve any requests. Clients of A fail too. Failure cascades through the entire system.

**THE BREAKING POINT:**
One slow database brings down 12 microservices in a chain reaction. Each service waits for the one below it. The entire platform is down because of one slow query.

**THE INVENTION MOMENT:**
"This is exactly why the Circuit Breaker pattern was created."

---

### 📘 Textbook Definition

The circuit breaker pattern (from Michael Nygard's "Release It!") monitors calls to a remote service. In CLOSED state, calls pass through normally and failures are counted. When the failure rate exceeds a threshold (e.g., 50%), the circuit OPENS - all calls fail immediately with a fallback. After a wait duration, the circuit goes to HALF-OPEN - a limited number of calls pass through. If they succeed, the circuit CLOSES. If they fail, it OPENS again. Resilience4j is the standard implementation in Spring Cloud, replacing Netflix Hystrix.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
If a downstream service is failing, stop calling it (fail fast), wait for recovery, then try again gradually.

**One analogy:**

> An electrical circuit breaker. When too much current flows (too many failures), the breaker trips (opens) - cutting power (stopping calls) to prevent fire (cascading failure). After the issue is resolved, you manually reset (half-open test), and if power flows normally (calls succeed), the breaker stays closed.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
@Service
public class PaymentService {

    @CircuitBreaker(
        name = "payment",
        fallbackMethod = "fallback")
    public Payment charge(
            PaymentReq req) {
        return restClient.post()
            .uri("http://payment-api/charge")
            .body(req)
            .retrieve()
            .body(Payment.class);
    }

    private Payment fallback(
            PaymentReq req,
            Throwable t) {
        log.warn("Payment unavailable,"
            + " queuing: {}", t.getMessage());
        return Payment.queued(req);
    }
}
```

```yaml
resilience4j:
  circuitbreaker:
    instances:
      payment:
        failure-rate-threshold: 50
        wait-duration-in-open-state: 30s
        sliding-window-size: 10
        minimum-number-of-calls: 5
        permitted-number-of-calls-in-
          half-open-state: 3
```

**Level 3 - How it works (mid-level):**

State machine:

```
  CLOSED (normal operation)
    |
  Failure rate > threshold (50%)
    |
  OPEN (fail fast, return fallback)
    |
  Wait duration expires (30s)
    |
  HALF-OPEN (test with limited calls)
    |
  Calls succeed? -> CLOSED
  Calls fail?    -> OPEN (restart wait)
```

Configuration explained:

| Setting                      | Value | Meaning                        |
| ---------------------------- | ----- | ------------------------------ |
| failure-rate-threshold       | 50    | Open at 50% failure            |
| sliding-window-size          | 10    | Last 10 calls measured         |
| minimum-number-of-calls      | 5     | Need 5 calls before evaluating |
| wait-duration-in-open-state  | 30s   | Wait before half-open          |
| permitted-calls-in-half-open | 3     | Test with 3 calls              |

**Level 4 - Mastery (senior/staff+):**

Combined patterns:

```java
@CircuitBreaker(name = "external")
@Retry(name = "external")
@TimeLimiter(name = "external")
@Bulkhead(name = "external")
public CompletableFuture<Data> call() {
    return CompletableFuture.supplyAsync(
        () -> externalApi.getData());
}
```

Execution order: Bulkhead -> TimeLimiter -> CircuitBreaker -> Retry -> Method.

Actuator integration:

```
GET /actuator/circuitbreakers

{
  "payment": {
    "state": "CLOSED",
    "failureRate": "10.0%",
    "numberOfBufferedCalls": 10,
    "numberOfFailedCalls": 1
  }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add `@CircuitBreaker` with a fallback."

**A Staff says:** "I design resilience as a layered strategy: timeout (TimeLimiter) -> retry (transient failures) -> circuit breaker (sustained failures) -> bulkhead (isolate failure domains). Fallbacks return degraded responses, not errors. I monitor circuit breaker state via Actuator/Grafana and alert on state transitions. I tune thresholds based on SLOs."

---

### 💻 Code Example

**BAD no resilience vs GOOD circuit breaker:**

```java
// BAD - no protection
public Data fetchData() {
    // If external-api is down,
    // this blocks for 30 seconds
    // (default timeout)
    // Exhausts thread pool
    // Cascading failure
    return restClient.get()
        .uri("http://external-api/data")
        .retrieve()
        .body(Data.class);
}

// GOOD - circuit breaker + fallback
@CircuitBreaker(name = "external",
    fallbackMethod = "cachedData")
@TimeLimiter(name = "external")
public CompletableFuture<Data> fetchData() {
    return CompletableFuture.supplyAsync(
        () -> restClient.get()
            .uri("http://external-api/data")
            .retrieve()
            .body(Data.class));
}

private CompletableFuture<Data> cachedData(
        Throwable t) {
    return CompletableFuture.completedFuture(
        cache.getLastKnown());
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** State machine that stops calls to failing services and provides fallbacks.

**KEY INSIGHT:** Fail fast instead of waiting. Prevent cascading failures.

**ANTI-PATTERN:** No fallback (circuit breaker returns error). Not monitoring state transitions.

**ONE-LINER:** "CLOSED -> failures -> OPEN (fail fast) -> wait -> HALF-OPEN -> test -> CLOSED."

**If you remember only 3 things:**

1. Three states: CLOSED (normal), OPEN (fail fast), HALF-OPEN (test)
2. Fallback returns degraded response, not error
3. Layer: timeout -> retry -> circuit breaker -> bulkhead

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Explain the circuit breaker pattern.**

**Answer:**
Three states: CLOSED (calls pass, failures counted), OPEN (calls fail immediately with fallback, preventing cascading failure), HALF-OPEN (limited test calls to check recovery).

Trigger: failure rate exceeds threshold (e.g., 50% of last 10 calls). Recovery: after wait duration, half-open allows test calls. If they succeed, circuit closes. If not, reopens.

Resilience4j is the standard in Spring Cloud. Configure via YAML. Monitor via Actuator.

---

**Q2 [SENIOR]: Design a resilience strategy for microservices.**

**Answer:**
Layered approach:

1. **Timeout (TimeLimiter):** Max 2 seconds per call. Fail fast.
2. **Retry:** 3 attempts for transient failures (503, connection timeout). Exponential backoff.
3. **Circuit Breaker:** Open at 50% failure. 30-second wait. Fallback returns cached/degraded data.
4. **Bulkhead:** Isolate thread pools per downstream service. Payment failures do not consume order service threads.
5. **Monitoring:** Grafana dashboard for circuit state transitions, failure rates, fallback rates.
6. **Fallbacks:** Always return useful degraded responses, not generic errors.

---

### 🔗 Related Keywords

**Prerequisites:** Microservices, Distributed Systems

**Builds on:** Service Discovery, API Gateway

**Alternatives:** Istio (service mesh circuit breaking), Envoy proxy

---

---

# Distributed Configuration

**TL;DR** - Spring Cloud Config Server centralizes configuration for all microservices in a Git repository, serving environment-specific properties via HTTP - eliminating config files baked into JARs and enabling runtime configuration changes without redeployment.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Each microservice has its own `application.yml` with database URLs, feature flags, and secrets. Changing a database URL requires redeploying the service. Different environments (dev, staging, prod) need different config files. Secrets are committed to Git.

---

### 📘 Textbook Definition

Spring Cloud Config provides server-side and client-side support for externalized configuration. The Config Server serves configuration from a backend store (Git, Vault, database) via REST API. Config clients (microservices) fetch their configuration at startup from the Config Server. Configuration is organized by `{application}/{profile}/{label}` (e.g., order-service/production/main). `@RefreshScope` enables runtime property refresh without restart.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
One Git repo holds all microservice configs. Services fetch their config at startup from a Config Server. Change Git, refresh services.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

Config Server:

```yaml
# Config Server application.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/org
            /config-repo
          search-paths: "{application}"
```

Config repo structure:

```
config-repo/
  order-service/
    application.yml      (all envs)
    application-prod.yml (prod only)
  payment-service/
    application.yml
    application-prod.yml
```

Client (microservice):

```yaml
spring:
  application:
    name: order-service
  config:
    import: configserver:http://config
      -server:8888
  profiles:
    active: prod
# Fetches: order-service/prod
```

**Level 3 - How it works (mid-level):**

```
  Microservice starts
       |
  Before context loads:
    GET http://config-server:8888
    /order-service/prod
       |
  Config Server:
    Check Git repo
    Merge: application.yml
           + application-prod.yml
           + order-service.yml
           + order-service-prod.yml
       |
  Return merged properties
       |
  Microservice: apply as PropertySource
  (overrides local application.yml)
```

Runtime refresh:

```java
@RefreshScope
@Component
public class FeatureFlags {
    @Value("${feature.new-checkout}")
    private boolean newCheckout;
    // Updated on POST /actuator/refresh
}
```

**Level 4 - Mastery (senior/staff+):**

Config precedence (highest to lowest):

1. Command line arguments
2. System properties / env vars
3. Config Server profile-specific
4. Config Server application-specific
5. Local application-{profile}.yml
6. Local application.yml

Secrets with Vault:

```yaml
spring:
  cloud:
    config:
      server:
        vault:
          host: vault.internal
          port: 8200
          scheme: https
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Config Server for centralized config."

**A Staff says:** "I use Config Server for non-sensitive properties and HashiCorp Vault for secrets. Kubernetes deployments use ConfigMaps + Secrets instead of Config Server. I implement `@RefreshScope` for runtime changes and Spring Cloud Bus for broadcast refresh across instances."

In Kubernetes: ConfigMaps and Secrets replace Config Server. Volume mounts or env vars inject config. No extra infrastructure needed.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Centralized configuration management for microservices.

**KEY INSIGHT:** In Kubernetes, ConfigMaps + Secrets replace Config Server.

**ANTI-PATTERN:** Secrets in Git. Config baked into JARs.

**ONE-LINER:** "Git-backed config, fetched at startup, refreshable at runtime."

**If you remember only 3 things:**

1. Config Server serves properties from Git via REST
2. @RefreshScope enables runtime config changes
3. In Kubernetes, use ConfigMaps/Secrets instead

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does Spring Cloud Config work?**

**Answer:**
Config Server serves configuration from a Git repo via REST. Microservices fetch their config at startup by application name and profile. Config repo is organized by `{application}/{profile}`.

Properties are merged: generic (`application.yml`) + service-specific (`order-service.yml`) + profile-specific (`order-service-prod.yml`). `@RefreshScope` enables runtime changes via `POST /actuator/refresh`. Spring Cloud Bus broadcasts refresh to all instances.

---

### 🔗 Related Keywords

**Prerequisites:** Spring Boot Externalized Configuration

**Builds on:** Service Discovery (Config Server registered)

**Alternatives:** Kubernetes ConfigMaps/Secrets, HashiCorp Consul, AWS Parameter Store

---

---

# Observability with Micrometer and Tracing

**TL;DR** - Micrometer provides a vendor-neutral metrics facade (like SLF4J for metrics) while Micrometer Tracing (formerly Spring Cloud Sleuth) adds distributed tracing with trace IDs propagated across services - giving you metrics, traces, and logs correlated by a single trace ID for debugging distributed systems.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A request fails in production. It passed through 5 microservices. Each service has its own logs. Which service caused the failure? Searching 5 log files for a timestamp match is unreliable. No way to trace a single request across services.

**THE BREAKING POINT:**
A user reports slow checkout. The request passes through gateway -> order -> inventory -> payment -> notification. Latency is 10 seconds. Which service is slow? Without distributed tracing, the team spends hours grepping logs.

**THE INVENTION MOMENT:**
"This is exactly why distributed tracing was created."

---

### 📘 Textbook Definition

Micrometer is a metrics instrumentation library providing a facade over monitoring systems (Prometheus, Datadog, CloudWatch). It collects metrics: counters, gauges, timers, distribution summaries. Micrometer Tracing adds distributed tracing by generating and propagating trace IDs and span IDs across HTTP calls, message queues, and async operations. Spring Boot Actuator exposes metrics via `/actuator/metrics` and `/actuator/prometheus`. Together, they provide the three pillars of observability: metrics, traces, and logs (correlated by trace ID).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Micrometer = metrics (counters, timers). Tracing = trace ID across services. Together = full observability.

**One analogy:**

> A FedEx tracking number. The trace ID is the tracking number that follows a package (request) across sorting centers (services). At each center, a new label (span) is added with timestamps. You can see the entire journey, timing at each stop, and where delays occurred.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

Metrics with Micrometer:

```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final MeterRegistry registry;

    public Order place(OrderReq req) {
        Timer.Sample sample =
            Timer.start(registry);
        try {
            Order order = process(req);
            registry.counter(
                "orders.placed",
                "type", req.getType())
                .increment();
            return order;
        } finally {
            sample.stop(registry.timer(
                "orders.duration"));
        }
    }
}
```

Tracing setup:

```yaml
management:
  tracing:
    sampling:
      probability: 1.0 # 100% in dev
  endpoints:
    web:
      exposure:
        include: health, metrics,
          prometheus
```

Dependency:

```xml
<dependency>
    <artifactId>
        micrometer-tracing-bridge-otel
    </artifactId>
</dependency>
<dependency>
    <artifactId>
        opentelemetry-exporter-otlp
    </artifactId>
</dependency>
```

**Level 3 - How it works (mid-level):**

Trace propagation:

```
  Gateway: trace-id=abc, span-id=001
  Header: traceparent: 00-abc-001-01
       |
  Order Service: trace-id=abc,
  span-id=002, parent=001
       |
  Payment Service: trace-id=abc,
  span-id=003, parent=002
       |
  Each service logs with trace-id:
  [abc] Processing order
  [abc] Charging payment
  [abc] Payment complete

  All logs searchable by trace-id=abc
```

Key metrics (auto-configured):

| Metric                      | Type  | Measures        |
| --------------------------- | ----- | --------------- |
| http.server.requests        | Timer | Request latency |
| jvm.memory.used             | Gauge | Memory usage    |
| hikaricp.connections.active | Gauge | DB pool usage   |
| spring.data.repository      | Timer | Query latency   |

**Level 4 - Mastery (senior/staff+):**

Custom observation (Spring 6):

```java
@Service
public class OrderService {
    private final ObservationRegistry
        registry;

    public Order place(OrderReq req) {
        return Observation
            .createNotStarted(
                "order.place", registry)
            .lowCardinalityKeyValue(
                "type", req.getType())
            .observe(() -> process(req));
        // Creates metric AND trace span
    }
}
```

Prometheus + Grafana stack:

```
  App -> Micrometer -> Prometheus
  (scrape /actuator/prometheus)
       |
  App -> OpenTelemetry -> Tempo/Jaeger
  (export traces via OTLP)
       |
  Grafana: dashboards + alerting
  Correlate: metrics <-> traces <-> logs
  via trace-id
```

Sampling strategy:

```yaml
management:
  tracing:
    sampling:
      probability: 0.1 # 10% in prod
# Sample 10% of traces to reduce cost
# Always trace errors (custom sampler)
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add Actuator and Prometheus."

**A Staff says:** "I design the observability stack: Micrometer metrics -> Prometheus -> Grafana for dashboards and alerting. OpenTelemetry traces -> Tempo/Jaeger for distributed tracing. Structured JSON logs with trace-id for log correlation. 10% sampling in production, 100% for errors. Custom `Observation` API for business metrics + traces in one call. SLO-based alerting (latency p99, error rate)."

---

### 💻 Code Example

**BAD no observability vs GOOD full stack:**

```java
// BAD - no metrics, no tracing
public Order place(OrderReq req) {
    return process(req);
    // No idea how long this takes
    // No way to trace across services
}

// GOOD - Observation API (metrics + trace)
public Order place(OrderReq req) {
    return Observation
        .createNotStarted(
            "order.place", registry)
        .lowCardinalityKeyValue(
            "type", req.getType())
        .observe(() -> process(req));
    // Creates timer metric AND
    // trace span automatically
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Micrometer = metrics facade. Tracing = distributed trace IDs. Together = observability.

**KEY INSIGHT:** Trace ID correlates metrics, traces, and logs across all services.

**ANTI-PATTERN:** No tracing in production. 100% sampling (expensive). Metrics without alerting.

**ONE-LINER:** "Micrometer for metrics, OpenTelemetry for traces, trace-id for correlation."

**If you remember only 3 things:**

1. Trace ID propagates across services via HTTP headers
2. Micrometer -> Prometheus (metrics), OpenTelemetry -> Jaeger/Tempo (traces)
3. Observation API = metrics + traces in one call (Spring 6+)

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How do you implement distributed tracing in Spring?**

**Answer:**
Add micrometer-tracing-bridge-otel and OpenTelemetry exporter. Spring auto-generates trace-id and span-id. Trace-id propagates via `traceparent` HTTP header. Each service adds its span. All logs include trace-id for correlation.

Stack: App -> Micrometer Tracing -> OpenTelemetry -> Jaeger/Tempo. Grafana visualizes the trace waterfall showing latency per service.

10% sampling in production to manage cost. 100% for errors.

---

**Q2 [SENIOR]: Design an observability strategy for a microservices platform.**

**Answer:**
Three pillars:

1. **Metrics:** Micrometer -> Prometheus. RED method: Rate, Errors, Duration per service. JVM metrics (memory, GC, threads). Custom business metrics (orders/sec).
2. **Traces:** OpenTelemetry -> Tempo. Distributed tracing across all services. 10% sampling, 100% for errors.
3. **Logs:** Structured JSON with trace-id. ELK or Loki for aggregation.

Correlation: Grafana links metrics -> traces -> logs via trace-id. SLO-based alerting: p99 latency > 500ms, error rate > 1%.

---

### 🔗 Related Keywords

**Prerequisites:** Spring Boot Actuator, HTTP Headers

**Builds on:** API Gateway (trace starts at gateway)

**Alternatives:** Datadog, New Relic, AWS X-Ray
