---
layout: default
title: "Micronaut - L5 Architecture"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 8
permalink: /micronaut/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut in Microservices Architecture](#micronaut-in-microservices-architecture) | high |
| 2 | [Micronaut vs Spring Migration Strategy](#micronaut-vs-spring-migration-strategy) | high |
| 3 | [Micronaut Distributed Systems Design](#micronaut-distributed-systems-design) | high |
| 4 | [Micronaut Serverless Architecture](#micronaut-serverless-architecture) | medium |

---

# Micronaut in Microservices Architecture

**Interview Weight:** high - Staff-level question.
Tests ability to place Micronaut in the broader
architecture and make framework selection decisions.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut is well-suited for microservices architectures
> requiring fast startup, low memory, and cloud-native
> deployment. Key capabilities: service discovery
> (Consul, Kubernetes DNS), client-side load balancing,
> circuit breaker, distributed tracing, and health
> endpoints for Kubernetes probes. The compile-time
> model means each service starts in under 1 second
> on JVM and scales to zero on Lambda/serverless.
> Choose Micronaut when startup latency and memory
> footprint are constraints.

**3 minutes (Staff):**

> Micronaut's architectural fit:
>
> API Gateway + Micronaut:
>   Gateway patterns: reactive HTTP clients aggregate
>   multiple service calls. Micronaut's non-blocking
>   HTTP client with circuit breaker (SmallRye Fault
>   Tolerance or @CircuitBreaker) handles upstream
>   failures. Reactive composition: Flux.merge() for
>   parallel calls, flatMap for sequential.
>
> Event-driven services:
>   Kafka consumers with @KafkaListener.
>   Exactly-once semantics with transactional producer.
>   Reactive consumers (Flowable) for high-throughput.
>   Micronaut handles backpressure automatically.
>
> Sidecar pattern (Kubernetes):
>   Micronaut services as lightweight sidecars.
>   <100MB native image: minimal resource impact.
>   Health checks: Kubernetes-native management
>   endpoints.
>
> Service mesh integration:
>   Istio/Linkerd handle mTLS, load balancing,
>   traffic management.
>   Micronaut: remove its own service discovery
>   (let the mesh handle it).
>   Keep Micronaut circuit breaker as code-level
>   defense.
>
> When NOT to use Micronaut:
>   Mature Spring ecosystem heavily used by team.
>   Spring Batch, Spring Integration workflows.
>   Complex Spring Security configurations.
>   Rapid prototype (Spring Boot + DevTools faster).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about where Micronaut
fits in a microservices architecture."

**(2) First principles:** "Microservices = many small
services. Each has startup cost, memory cost, operational
overhead. Micronaut minimizes all three."

**(3) Bridge:** "Micronaut in microservices is like
using Go-lightweight containers for Java. You get
the Java ecosystem with near-Go operational efficiency."

---

### 🎓 Answers by Seniority

**Staff:** "Micronaut excels in three microservices
scenarios: (1) Lambda/serverless where cold start
is charged; (2) high-density Kubernetes clusters where
memory per pod is constrained; (3) API gateways and
aggregation services where reactive non-blocking is
critical. It's NOT the right choice for teams deeply
invested in Spring ecosystem libraries (Spring Batch,
Spring Security, Spring Integration) - the migration
cost outweighs the startup benefit."

**Principal:** "At org level: Micronaut and Quarkus
occupy the same niche. The decision between them is
team familiarity (Quarkus = CDI/JAX-RS familiar vs
Micronaut = custom DI). Both are production-ready.
Standardize on one to reduce cognitive overhead across
teams."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Microservices patterns, service mesh, when to choose |
| Principal | 15 min | Org-level framework selection, migration strategy |

---

**[STAFF] Q1 - How do you design circuit breakers
across Micronaut microservices?**

*Why they ask:* Resilience design at system level.

Circuit breaker placement:
```java
// At the HTTP client (consumer side)
@Singleton
@CircuitBreaker(
    reset = "30s",
    attempts = "5",
    delay = "500ms",
    multiplier = "2")
@Retryable(
    attempts = "3",
    delay = "200ms")
public interface InventoryClient {
    @Get("/inventory/{id}")
    Optional<InventoryDto> findById(
        @PathVariable Long id);
}

@Singleton
@Fallback
public class InventoryClientFallback
        implements InventoryClient {
    @Override
    public Optional<InventoryDto> findById(
            Long id) {
        // Check local cache first
        return cache.get("inventory:" + id);
        // If cache miss: return empty
        // Caller degrades gracefully
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Circuit breaker states:
- CLOSED: normal operation
- OPEN: failures exceed threshold, reject calls
- HALF-OPEN: allow one call to test if service recovered

When circuit opens: @Fallback is invoked.
No fallback: CircuitOpenException thrown.

Design decisions:
1. Circuit breaker per critical dependency (not global)
2. Fallback strategy: cache hit or degraded response
3. Alert when circuit opens: Micrometer counter
4. Timeout: configure both @Retryable timeout and
   the HTTP client connect/read timeout

```java
// Metrics: monitor circuit breaker state
registry.gauge(
    "circuit_breaker.inventory.state",
    0);  // 0=closed, 1=open, 2=half-open
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Fallback with cached
data vs returning error. Cache-based fallback = graceful
degradation instead of cascade failure.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Service discovery, load balancing, reactive HTTP client. |
| Hiring Manager | Micronaut fits in our microservices platform. |
| Bar Raiser | Circuit breaker design, fallback strategy, service mesh interaction. |
| Principal | Org-level framework standardization, when Micronaut vs Spring vs Quarkus. |

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


# Micronaut vs Spring Migration Strategy

**Interview Weight:** high - Migration experience is
frequently asked at senior/staff level.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut-to-Spring migration (or reverse) requires
> understanding the DI model differences. Micronaut
> DI annotations map closely: @Singleton → @Singleton,
> @Inject → @Inject (JSR-330 same spec), @Qualifier →
> @Named. The key differences: no @Autowired (use
> @Inject), no Spring Security complex DSL (use Micronaut
> Security), no Spring Data magic query derivation in
> the same way (use Micronaut Data). Migrate incrementally:
> controller → service → repository, not all at once.

**3 minutes (Staff):**

> Spring → Micronaut migration path:
>
> Phase 1: Replace DI annotations (low risk):
>   @Autowired → @Inject (JSR-330 standard)
>   @Service, @Repository, @Component → @Singleton
>   @Bean (in @Configuration) → @Bean (in @Factory)
>   @Value → @Value (same syntax)
>   @ConfigurationProperties → @ConfigurationProperties
>
> Phase 2: Replace data access:
>   Spring Data JPA → Micronaut Data JPA
>   Same @Entity, same @Repository interface
>   Different: @Transactional behavior (self-invoke OK)
>
> Phase 3: Replace HTTP layer:
>   @RestController → @Controller
>   @GetMapping → @Get
>   @RequestBody → @Body
>   @PathVariable → @PathVariable (same)
>   @RequestParam → @QueryValue
>
> Phase 4: Replace security:
>   Spring Security config DSL → application.yml config
>   @PreAuthorize("hasRole('X')") → @Secured("ROLE_X")
>   Spring Security UserDetailsService →
>     AuthenticationProvider
>
> Phase 5: Replace testing:
>   @SpringBootTest → @MicronautTest
>   @MockBean → @MockBean (micronaut-test-mockito)
>
> Common migration pitfalls:
>   @Configuration + @Bean: different semantics.
>     Micronaut: @Factory + @Bean
>   @Conditional: use @Requires in Micronaut
>   Spring events: use ApplicationEventPublisher
>     (same API, different implementation)
>   AOP: no @EnableAspectJAutoProxy needed

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about migrating from
Spring Boot to Micronaut - the strategy and pitfalls."

**(2) First principles:** "Migration = map old concepts
to new ones. Find equivalents. Migrate incrementally
to limit risk."

**(3) Bridge:** "Spring → Micronaut is like moving from
one city to another with the same street grid. Most
roads have equivalents, but some are renamed."

---

### 🎓 Answers by Seniority

**Staff:** "The safest migration strategy: start with
a new Micronaut service that calls Spring services
via HTTP. Gradually rewrite service by service. Never
rewrite the whole monolith to Micronaut at once.
The DI mapping is straightforward (JSR-330 annotations
work in both). The risk is in Spring-specific features:
Spring Security DSL, Spring Batch, Spring Integration."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Migration phases, annotation mapping, pitfalls |
| Principal | 15 min | Strangler fig pattern, risk management, rollback |

---

**[STAFF] Q1 - What is the strangler fig pattern
and how does it apply to Spring → Micronaut migration?**

*Why they ask:* Incremental migration strategy.

Strangler Fig: wrap the old system gradually. New
functionality goes into the new system. Old functionality
is migrated piece by piece. Eventually the old system
is strangled out.

Applied to Spring → Micronaut:
1. API Gateway (nginx, Kubernetes ingress) routes
   all traffic to existing Spring monolith.
2. Extract first service (e.g., OrderService) to
   Micronaut. Deploy alongside monolith.
3. Gateway: route /orders/* to Micronaut service.
   All other traffic → Spring monolith.
4. Monitor: metrics, logs, errors for /orders/*.
5. If stable: extract next service.
6. Repeat until monolith is empty.

Rollback at each step: gateway routing change is
reversible. If Micronaut OrderService has bugs:
route /orders/* back to monolith.

Risk management:
- Never migrate the database schema in the same step
  as the service migration.
- Share the database initially (dual writes if needed).
- Migrate DB schema in a separate step with backward
  compatibility.

*What separates good from great:* Separating service
migration from database migration - doing both at
once doubles the risk.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Annotation mapping table, @Factory, @Requires. |
| Hiring Manager | How long will migration take? Risk? |
| Bar Raiser | Strangler fig, database migration decoupling, rollback strategy. |
| Principal | Business continuity during migration, team training, feature freeze. |

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


# Micronaut Distributed Systems Design

**Interview Weight:** high - Staff-level architecture
question. Tests understanding of distributed system
challenges addressed by Micronaut features.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut provides building blocks for distributed
> systems: service discovery, client-side load balancing,
> circuit breaker, distributed tracing, health checks.
> The core challenge remains the same as any distributed
> system: partial failure, network unreliability,
> eventual consistency. Micronaut's reactive HTTP client
> and circuit breaker handle partial failure.
> Event-driven messaging (Kafka) handles eventual
> consistency. Distributed tracing handles observability.

**3 minutes (Staff):**

> Distributed system concerns and Micronaut's tools:
>
> Partial failure:
>   @CircuitBreaker + @Fallback: fail fast, degrade.
>   @Retryable: handle transient failures.
>   Timeout configuration: don't wait forever.
>
> Network partitions:
>   Service discovery health checks detect failures.
>   Consul health check → instance removed from routing.
>   Kubernetes readiness probe → pod removed from LB.
>
> Data consistency:
>   @Transactional for local DB consistency.
>   Saga pattern for distributed transactions.
>   Outbox pattern for at-least-once event publishing.
>   Micronaut Kafka transactions for consume-produce
>   exactly-once.
>
> Observability:
>   Distributed tracing: trace spans across services.
>   Structured logs with traceId/spanId in MDC.
>   Metrics: Micrometer for all services, common
>     Prometheus scraping.
>
> Configuration management:
>   Consul KV store / AWS SSM: centralized config.
>   /refresh endpoint: push config changes.
>   @Refreshable beans: reload on config change.
>
> CAP theorem in practice:
>   Micronaut services: AP (available + partition tolerant)
>   via circuit breaker + fallback.
>   Database: CP (consistent + partition tolerant).
>   Design: accept eventual consistency at the service
>   boundary; maintain strong consistency in the DB.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how Micronaut
helps with distributed systems challenges."

**(2) First principles:** "Distributed systems have
8 fallacies: network is reliable, latency is zero,
bandwidth is infinite, topology doesn't change, etc.
Every distributed system must handle these violations."

**(3) Bridge:** "Micronaut's features are answers to
the 8 fallacies: circuit breaker for unreliable network,
reactive non-blocking for latency, health checks for
topology changes."

---

### 🎓 Answers by Seniority

**Staff:** "For distributed data consistency: use the
outbox pattern for all inter-service events. @Transactional
for the local DB operation + outbox write. Separate
poller publishes events. This gives at-least-once
delivery without distributed transactions (which are
fragile in microservices). Consumers must be idempotent."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Distributed system challenges, Micronaut tool mapping |
| Principal | 15 min | CAP theorem trade-offs, saga patterns, event-driven design |

---

**[STAFF] Q1 - How would you implement a saga pattern
for a multi-step order process in Micronaut?**

*Why they ask:* Distributed transaction architecture.

Saga: sequence of local transactions, each publishing
an event to trigger the next. On failure: compensating
transactions undo completed steps.

```
CreateOrder → ReserveInventory → ChargePayment
           ↓ (fail anywhere)
CancelOrder ← ReleaseInventory ← RefundPayment
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Choreography-based saga in Micronaut Kafka:

```java
// Step 1: Order Service
@Singleton
public class OrderSaga {

    @Transactional
    public Order startOrder(CreateOrderReq req) {
        Order order = repo.save(Order.from(req));
        // Publish event to trigger next step
        eventProducer.send(
            order.getId(),
            new OrderCreatedEvent(order.getId(),
                req.getProductId(), req.getQty()));
        return order;
    }

    // Compensation: on payment failure
    @KafkaListener(groupId="order-saga")
    @Topic("payment-failed-events")
    public void onPaymentFailed(
            PaymentFailedEvent event) {
        // Compensating transaction
        orderService.cancel(event.getOrderId());
        eventProducer.send(
            event.getOrderId(),
            new OrderCancelledEvent(
                event.getOrderId()));
    }
}

// Step 2: Inventory Service
@KafkaListener(groupId="inventory-saga")
@Topic("order-created-events")
public class InventoryStep {
    @Transactional
    public void reserve(OrderCreatedEvent event) {
        try {
            inventory.reserve(
                event.getProductId(), event.getQty());
            producer.send(
                event.getOrderId(),
                new InventoryReservedEvent(...));
        } catch (InsufficientStockException e) {
            producer.send(
                event.getOrderId(),
                new InventoryFailedEvent(...));
        }
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Compensation is critical: every step that can succeed
must have a compensating transaction.

*What separates good from great:* Distinguishing
choreography (events) from orchestration (saga
orchestrator service). Choreography is simpler for
linear sagas; orchestration for complex branching.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Distributed tracing, circuit breaker, health checks. |
| Hiring Manager | Micronaut for reliable distributed systems. |
| Bar Raiser | Saga pattern, outbox pattern, CAP theorem, compensation design. |
| Principal | Choreography vs orchestration, saga complexity management. |

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


# Micronaut Serverless Architecture

**Interview Weight:** medium - Lambda/serverless is
a primary Micronaut use case. Tested for cold start
optimization and serverless design patterns.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut for serverless: @FunctionBean for AWS Lambda,
> GraalVM native image for <100ms cold starts, or JVM
> mode with Provisioned Concurrency for warm instances.
> The compile-time DI means no classpath scanning during
> cold start - the main JVM warm-up time savings.
> Design principles: stateless functions, connection
> pool of 1-2 (reused between Lambda invocations),
> async initialization for slow resources.

**3 minutes (Staff):**

> Lambda deployment options:
>
> JVM mode:
>   Micronaut JAR + Lambda Java runtime.
>   Cold start: 500ms-2s (depends on dependencies).
>   Warm invocation: <10ms overhead.
>   Trade-off: cold start latency vs development ease.
>
> GraalVM native image:
>   Compiled to native executable.
>   Cold start: <100ms (often 20-50ms).
>   Custom runtime required (Amazon Linux).
>   Trade-off: build complexity vs cold start.
>
> Provisioned Concurrency (JVM + GraalVM):
>   AWS keeps N instances warm.
>   No cold starts for those instances.
>   Cost: pay for idle instances.
>   Use when: cold start is user-visible and SLA-critical.
>
> Connection pool design for Lambda:
>   Lambda instances share no state between functions.
>   Each Lambda instance: its own connection pool.
>   Connection pool at 1-2 max connections.
>   Why: Lambda auto-scales to hundreds of instances.
>     100 instances × 20 connections = 2000 connections.
>     Exceeds RDS max connections.
>   RDS Proxy: connection pooler for Lambda → DB.
>
> Function design principles:
>   Idempotent: SQS triggers retry on failure.
>   Stateless: no in-memory state between invocations.
>   Fast init: @Lazy for unused dependencies.
>   Context reuse: connections persist between warm invocations.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about designing Micronaut
services for serverless (AWS Lambda)."

**(2) First principles:** "Serverless = function as unit.
Scale to zero. Pay per invocation. Cold start = startup
time. Design for statelessness and fast startup."

**(3) Bridge:** "Micronaut for serverless is like
bringing a racing bicycle to a race instead of a
touring bicycle. Same Java code, optimized for the
track."

---

### 🎓 Answers by Seniority

**Staff:** "Connection pool for Lambda is the most
overlooked design mistake. 100 Lambda instances × 20
connections each = 2000 DB connections. PostgreSQL
max connections: 100-200. The fix: RDS Proxy in front
of the DB (pools connections across Lambda instances)
AND reduce Lambda pool size to 1-2."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | JVM vs native, cold start, Lambda function design |
| Staff | 12 min | Connection pool problem, RDS Proxy, Provisioned Concurrency |

---

**[STAFF] Q1 - How do you decide between JVM mode,
native image, and Provisioned Concurrency for a
Lambda function?**

*Why they ask:* Architecture decision framework.

Decision matrix:

|  | Cold start | Dev complexity | Cost |
|---|---|---|---|
| JVM mode | 500ms-2s | Low | Pay per invocation |
| Native image | <100ms | Medium (native build) | Pay per invocation |
| Provisioned concurrency | ~0ms | Low | Pay for idle capacity |

When to use:
- JVM: user doesn't see cold start (async processing,
  background jobs), or cold starts are infrequent.
- Native image: user-facing API, cold start is visible,
  team comfortable with native build pipeline.
- Provisioned concurrency: SLA requires <50ms warm-up
  for ALL invocations, cost is acceptable.

Hybrid approach:
- Provisioned Concurrency for baseline traffic (user-facing)
- Burst capacity: auto-scaling Lambda instances accept
  cold starts for overflow traffic

Most common production choice for user-facing APIs:
native image + RDS Proxy + minimal Provisioned Concurrency
for peak hours.

*What separates good from great:* Hybrid Provisioned
Concurrency for baseline + native for burst.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @FunctionBean, Lambda handler, native runtime. |
| Hiring Manager | Lambda = no server management, scale to zero. |
| Bar Raiser | Connection pool problem, RDS Proxy, decision matrix. |
| Principal | Cost modeling: Provisioned Concurrency vs always-on vs native. |

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



