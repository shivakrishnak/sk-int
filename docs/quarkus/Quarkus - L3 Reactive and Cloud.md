---
layout: default
title: "Quarkus - L3 Reactive and Cloud"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 5
permalink: /quarkus/l3-reactive-and-cloud/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus Reactive Messaging and Kafka](#quarkus-reactive-messaging-and-kafka) | critical |
| 2 | [Quarkus Security and OIDC](#quarkus-security-and-oidc) | critical |
| 3 | [Quarkus OpenTelemetry and Tracing](#quarkus-opentelemetry-and-tracing) | high |
| 4 | [Quarkus Kubernetes Operator Pattern](#quarkus-kubernetes-operator-pattern) | high |
| 5 | [Quarkus Multi-Tenancy Patterns](#quarkus-multi-tenancy-patterns) | high |

---

# Quarkus Reactive Messaging and Kafka

**Interview Weight:** critical - Kafka integration is
a top interview topic for microservices roles. Tested
for both producer/consumer patterns and failure handling.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus SmallRye Reactive Messaging (quarkus-smallrye-reactive-messaging-kafka)
> provides declarative Kafka integration. @Incoming("channel")
> and @Outgoing("channel") on CDI methods define message
> processing. Channels are configured in application.properties
> with connector type (smallrye-kafka), topic name,
> and serializers. Messages are Mutiny types: the method
> can return void (acknowledgment), Uni<Void> (async ack),
> Message<T> (manual ack).

**3 minutes (Senior):**

> Core annotations:
>
> @Incoming("orders-in"):
>   Consume from a channel.
>   Method is called for each message.
>   Return type determines ack behavior.
>
> @Outgoing("orders-out"):
>   Produce to a channel.
>   Method called to produce messages.
>   Return type = message value.
>
> @Incoming + @Outgoing (transformer):
>   Method consumes and produces (pipeline).
>
> Processing patterns:
>
> void process(OrderCreated event):
>   Auto-ack on method return.
>   Exception = nack (retry or DLQ).
>
> Uni<Void> process(OrderCreated event):
>   Auto-ack on Uni completion.
>   Uni failure = nack.
>
> Message<OrderCreated> process(...):
>   Manual ack: msg.ack() or msg.nack().
>   Full control over commit offset.
>
> Kafka configuration:
>   quarkus.kafka.bootstrap-servers=localhost:9092
>   mp.messaging.incoming.orders-in.connector=
>     smallrye-kafka
>   mp.messaging.incoming.orders-in.topic=orders
>   mp.messaging.incoming.orders-in.group.id=
>     order-service
>   mp.messaging.incoming.orders-in.auto.offset.reset=
>     earliest
>
> Error handling:
>   Default: nack causes re-delivery (up to retry limit).
>   mp.messaging.incoming.orders-in.failure-strategy=
>     dead-letter-queue
>   dead-letter-queue sends to orders-in-dlq topic.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kafka integration
in Quarkus using SmallRye Reactive Messaging."

**(2) First principles:** "Messaging = decouple producers
from consumers via a topic. Kafka = durable, ordered,
partitioned topic."

**(3) Bridge:** "SmallRye annotations are like Spring
@KafkaListener and @SendTo but with reactive processing."

---

### 💻 Code Example

```java
// Consumer: process incoming Kafka messages
@ApplicationScoped
public class OrderConsumer {

    @Inject
    OrderService orderService;

    // Simple: auto-ack, blocking processing
    @Incoming("order-created")
    @Blocking  // Use worker thread for JDBC
    public void onOrderCreated(
            OrderCreatedEvent event) {
        try {
            orderService.processCreated(event);
        } catch (NonRetryableException e) {
            // Log but don't rethrow
            // Re-thrown exception = nack = retry
            log.error("Skipping: {}", e.getMessage());
        }
    }

    // Reactive: manual ack for exactly-once semantics
    @Incoming("payment-processed")
    public Uni<Void> onPaymentProcessed(
            Message<PaymentEvent> message) {
        PaymentEvent event =
            message.getPayload();
        return orderService
            .markPaid(event.getOrderId(),
                      event.getAmount())
            .onItem()
            .invoke(() -> log.info(
                "Order {} paid", event.getOrderId()))
            .chain(() -> message.ack())  // Commit offset
            .onFailure()
            .call(e -> {
                log.error("Payment failed", e);
                return message.nack(e);
                // Sends to DLQ if configured
            });
    }
}

// Producer: publish to Kafka
@ApplicationScoped
public class OrderProducer {

    @Inject
    @Channel("order-events-out")
    Emitter<OrderEvent> orderEmitter;

    public void publishOrderCreated(Order order) {
        OrderEvent event = OrderEvent.created(order);
        // Send with key for partitioning
        orderEmitter.send(
            Message.of(event)
                .addMetadata(
                    OutgoingKafkaRecordMetadata
                        .<String>builder()
                        .withKey(
                            order.getCustomerId()
                                .toString())
                        .withTopic("order-events")
                        .build()));
    }

    // Reactive emit
    public Uni<Void> publishAsync(
            OrderEvent event) {
        return Uni.createFrom()
            .completionStage(
                orderEmitter.send(event));
    }
}

// Transformer: consume and produce
@ApplicationScoped
public class OrderEnricher {

    @Inject
    CustomerService customerService;

    @Incoming("orders-raw")
    @Outgoing("orders-enriched")
    public Uni<EnrichedOrder> enrich(
            OrderCreatedEvent event) {
        return customerService
            .findById(event.getCustomerId())
            .map(customer ->
                EnrichedOrder.from(event, customer));
    }
}
```

```properties
# application.properties
quarkus.kafka.bootstrap-servers=localhost:9092

# Consumer channel
mp.messaging.incoming.order-created.connector=\
  smallrye-kafka
mp.messaging.incoming.order-created.topic=\
  order-created-events
mp.messaging.incoming.order-created.group.id=\
  order-processor
mp.messaging.incoming.order-created.auto.offset.reset=\
  earliest
mp.messaging.incoming.order-created.failure-strategy=\
  dead-letter-queue
mp.messaging.incoming.order-created.dead-letter-queue\
  .topic=order-created-events-dlq

# Producer channel
mp.messaging.outgoing.order-events-out.connector=\
  smallrye-kafka
mp.messaging.outgoing.order-events-out.topic=\
  order-events
mp.messaging.outgoing.order-events-out\
  .value.serializer=\
  io.quarkus.kafka.client.serialization\
  .JsonbSerializer
```

> **Code walkthrough:** @Incoming("payment-processed")
> with Message<T> return gives manual control: message.ack()
> commits the Kafka offset, message.nack() sends to the
> dead-letter-queue topic. The reactive chain (.chain(() ->
> message.ack())) ensures ack only fires after successful
> processing. The @Outgoing Emitter in publishOrderCreated
> adds Kafka-specific metadata (partition key) so all
> events for a customer go to the same partition. The
> transformer (@Incoming + @Outgoing) forms a processing
> pipeline stage.

---

### ⚖️ Comparison Table

| Pattern | Ack | Use Case |
|---|---|---|
| void method | Auto-ack on return | Simple fire-and-forget processing |
| Uni<Void> | Auto-ack on Uni complete | Async processing, reactive JDBC |
| Message<T> manual ack | Explicit ack/nack | Exactly-once, custom error handling |
| @Incoming+@Outgoing | After outgoing send | Transformation pipelines |

---

### 🚨 Failure Modes and Diagnosis

**Problem 1: Messages stuck in DLQ, never reprocessed.**
Diagnosis: DLQ is a Kafka topic. No consumer reads it.
Fix: create a separate consumer for the DLQ topic.
On fix deployment, replay from DLQ.

**Problem 2: Consumer lag growing.**
Diagnosis: `kafka-consumer-groups.sh --describe --group order-processor`
Look at LAG column.
Fix: increase partition count, add consumer replicas.

**Problem 3: Duplicate processing after pod restart.**
Diagnosis: at-least-once delivery (Kafka default).
Auto-ack before processing = message lost on crash.
Fix: process-then-ack pattern (manual ack in Message<T>).
For strict exactly-once: idempotency key in DB.

---

### 🎓 Answers by Seniority

**Junior:** "@Incoming to consume, @Outgoing to produce.
Configure channel with connector=smallrye-kafka in
application.properties."

**Senior:** "Auto-ack methods risk message loss on pod
crash. Manual ack with Message<T> ensures ack only
after successful processing. DLQ configuration is
essential for production: messages that repeatedly
fail get sent to a DLQ topic for investigation, not
silently dropped."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Manual ack, DLQ, consumer patterns |
| Staff | 14 min | Exactly-once, consumer lag, partition design |

---

**[SENIOR] Q1 - How do you achieve idempotent
processing with Quarkus Kafka consumers?**

*Why they ask:* At-least-once delivery creates duplicates.

Kafka guarantee: at-least-once. Same message may arrive
multiple times (rebalance, restart, retry).

Pattern: store processed message IDs in DB:

```java
@ApplicationScoped
public class IdempotentOrderConsumer {

    @Inject
    ProcessedMessageRepository processed;

    @Incoming("order-created")
    @Blocking
    @ReactiveTransactional
    public void onOrderCreated(
            Message<OrderCreatedEvent> message) {
        IncomingKafkaRecordMetadata<?> meta =
            message.getMetadata(
                IncomingKafkaRecordMetadata.class)
            .orElseThrow();

        // Unique ID: topic + partition + offset
        String msgId = meta.getTopic() + "-" +
            meta.getPartition() + "-" +
            meta.getOffset();

        if (processed.exists(msgId)) {
            log.info("Skipping duplicate: {}", msgId);
            message.ack();
            return;
        }

        OrderCreatedEvent event = message.getPayload();
        orderService.processCreated(event);
        processed.save(msgId);
        message.ack();
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

The idempotency key is topic+partition+offset - unique
per message in Kafka. Store in DB (small table). Check
before processing. Ack either way.

*What separates good from great:* topic+partition+offset
as the exact idempotency key, not application-level IDs.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Incoming, @Outgoing, configuration. |
| Hiring Manager | Event-driven architecture with Kafka. |
| Bar Raiser | Manual ack, DLQ, idempotency, exactly-once. |
| Peer Engineer | "Added idempotency table. Duplicate processing incidents: 12/month → 0." |

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


# Quarkus Security and OIDC

**Interview Weight:** critical - Security is a mandatory
topic in senior interviews. OIDC/JWT is the dominant
pattern for microservice auth.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus OIDC (quarkus-oidc) provides JWT-based
> authentication with OpenID Connect providers (Keycloak,
> Auth0, Azure AD). @RolesAllowed("admin") on resource
> methods restricts access. SecurityIdentity provides
> the authenticated principal. JWT claims accessible
> via JsonWebToken injection. For service-to-service:
> OIDC client credentials flow. Token validation happens
> locally against the JWKS URI (no network call per
> request after initial key fetch).

**3 minutes (Senior):**

> OIDC configuration:
>
> quarkus.oidc.auth-server-url=
>   https://keycloak/realms/myapp
> quarkus.oidc.client-id=order-service
> quarkus.oidc.credentials.secret=${OIDC_SECRET}
> quarkus.oidc.application-type=service
>   (service: validates bearer tokens)
>   (web-app: OAuth2 authorization code flow)
>
> Authorization annotations:
>   @RolesAllowed({"admin", "manager"})
>   @Authenticated (any authenticated user)
>   @PermitAll (no auth required)
>   @DenyAll (always deny)
>
> SecurityIdentity injection:
>   @Inject SecurityIdentity identity;
>   identity.getPrincipal().getName(): username/subject
>   identity.getRoles(): roles from JWT
>   identity.hasRole("admin"): role check
>
> JsonWebToken injection:
>   @Inject JsonWebToken jwt;
>   jwt.getClaim("tenant-id"): custom claim
>   jwt.getSubject(): user ID
>   jwt.getGroups(): groups claim
>
> Service-to-service:
>   quarkus-oidc-client: get service token.
>   @OidcClientFilter on REST client:
>     auto-attach token to outgoing calls.
>
> Multi-tenancy:
>   quarkus.oidc.tenant-id for tenant routing.
>   TenantResolver: select tenant from request.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Quarkus security -
JWT authentication and authorization."

**(2) First principles:** "Auth = who are you? (JWT token).
Authz = what can you do? (roles/permissions)."

**(3) Bridge:** "Quarkus OIDC is Spring Security's
@PreAuthorize + JWT support using the MicroProfile
JWT standard."

---

### 💻 Code Example

```java
// Secured REST resource
@Path("/api/v1/orders")
@Produces(MediaType.APPLICATION_JSON)
@Authenticated  // Require auth for all methods
public class OrderResource {

    @Inject
    SecurityIdentity identity;

    @Inject
    JsonWebToken jwt;

    @Inject
    OrderService orderService;

    // Any authenticated user can view their orders
    @GET
    public Uni<List<OrderDto>> listMyOrders(
            @QueryParam("status") String status) {
        String customerId =
            identity.getPrincipal().getName();
        return orderService.findByCustomer(
            customerId, status);
    }

    // Only admins can view all orders
    @GET
    @Path("/all")
    @RolesAllowed("admin")
    public Uni<List<OrderDto>> listAllOrders() {
        return orderService.listAll();
    }

    // Extract custom claim from JWT
    @POST
    public Uni<OrderDto> createOrder(
            @Valid @RequestBody
            CreateOrderRequest request) {
        // Get tenant from JWT custom claim
        String tenantId =
            jwt.getClaim("tenant-id");
        String userId =
            jwt.getSubject();
        return orderService.create(
            request, userId, tenantId);
    }

    // Admin-only delete
    @DELETE
    @Path("/{id}")
    @RolesAllowed({"admin", "order-manager"})
    public Uni<Response> cancelOrder(
            @PathParam("id") Long id) {
        return orderService.cancel(id)
            .map(o -> Response.noContent().build());
    }
}

// Service-to-service with OIDC client
@ApplicationScoped
@RegisterRestClient(
    configKey = "inventory-service")
@OidcClientFilter  // Auto-attach service token
public interface InventoryClient {

    @GET
    @Path("/api/v1/items/{id}")
    Uni<InventoryItem> findItem(
            @PathParam("id") Long itemId);
}

// Custom security annotation
@Retention(RetentionPolicy.RUNTIME)
@RolesAllowed({"admin", "super-admin"})
public @interface AdminOnly {}

// Usage
@DELETE
@Path("/{id}")
@AdminOnly  // Custom annotation
public Uni<Response> delete(
        @PathParam("id") Long id) { ... }
```

```properties
# application.properties
quarkus.oidc.auth-server-url=\
  https://keycloak.company.com/realms/prod
quarkus.oidc.client-id=order-service
quarkus.oidc.credentials.secret=${OIDC_SECRET}
quarkus.oidc.application-type=service

# Service-to-service client
quarkus.oidc-client.auth-server-url=\
  https://keycloak.company.com/realms/prod
quarkus.oidc-client.client-id=order-service
quarkus.oidc-client.credentials.secret=${OIDC_SECRET}
quarkus.oidc-client.grant.type=client-credentials
```

> **Code walkthrough:** @Authenticated on the class requires
> a valid JWT for every endpoint. @RolesAllowed("admin")
> on listAllOrders() additionally requires the "admin"
> role. SecurityIdentity.getPrincipal().getName() returns
> the JWT subject claim (typically user ID). jwt.getClaim("tenant-id")
> extracts a custom claim from the token payload. @OidcClientFilter
> on the REST client interface automatically obtains
> a service-to-service token using client credentials
> flow and attaches it as a Bearer token.

---

### ⚠️ Common Misconceptions

1. "JWT validation requires a call to Keycloak per request."
   False: Quarkus validates JWT locally using the JWKS
   public keys fetched once at startup. Zero network
   calls per request for JWT validation.

2. "@RolesAllowed checks claims in the JWT automatically."
   Partially true: Quarkus maps JWT groups/roles claims
   to CDI roles. Configure quarkus.oidc.roles.role-claim-path
   if your JWT uses a custom path.

---

### 🚨 Failure Modes and Diagnosis

**401 on every request:**
Check: JWT expiry. curl -v to see WWW-Authenticate header.
Check: OIDC server URL (auth-server-url correct?).
Check: application-type=service (not web-app).

**403 despite correct role:**
Check: jwt.getClaim("groups") or jwt.getClaim("roles")
in Dev UI. Is the role in the JWT? Map the right claim path.
Configure: quarkus.oidc.roles.role-claim-path=realm_access/roles

**Token validation fails in native image:**
TLS certificate validation. Configure:
quarkus.tls.trust-all=true (dev only!) or
import cert into native image truststore.

---

### 🎓 Answers by Seniority

**Junior:** "@Authenticated requires auth. @RolesAllowed
restricts by role. Inject JsonWebToken for claims. Configure
OIDC in application.properties."

**Senior:** "JWT validation is local against JWKS -
no network hop per request. @OidcClientFilter automates
service-to-service token management. Multi-tenancy:
implement TenantResolver to select tenant config from
request headers. Role claim path mapping: different
OIDC providers put roles in different JWT fields."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | OIDC config, @RolesAllowed, service-to-service auth |
| Staff | 14 min | Multi-tenancy, JWKS rotation, JWT claim mapping |

---

**[SENIOR] Q1 - How do you handle JWKS key rotation
without downtime in Quarkus?**

*Why they ask:* Production security operations.

JWKS rotation: Keycloak/IDP rotates signing keys.
JWT signed with old key becomes invalid after rotation.

Quarkus OIDC handles this automatically:
1. JWT validation fails with old key.
2. Quarkus fetches fresh JWKS from the IDP.
3. Retries validation with new key.
4. If valid: request succeeds. No manual intervention.

Configuration:
```properties
# Retry on JWKS fetch failure
quarkus.oidc.token.forced-jwks-refresh-interval=5M
# Cache JWKS for 1 hour
quarkus.oidc.token.jwks-refresh-interval=1H
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Manual rotation scenario (cert expiry):
- OIDC provider announces new key.
- Publishes both old and new in JWKS.
- Tokens signed with new key start appearing.
- Old key removed after tokens expire (access token TTL).
- Quarkus fetches JWKS on validation failure - zero downtime.

The risk: if OIDC provider removes old key before existing
tokens expire, users mid-session get 401. Standard
practice: overlap period = access token TTL (5-15 min).

*What separates good from great:* Automatic JWKS refresh
on validation failure - no pod restarts needed.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | OIDC config, @RolesAllowed, SecurityIdentity. |
| Hiring Manager | Security in production microservices. |
| Bar Raiser | JWKS rotation, service-to-service flow, multi-tenancy. |
| Peer Engineer | "Keycloak key rotation caused 30 minutes of 401s. Added forced-jwks-refresh. Zero incidents since." |

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


# Quarkus OpenTelemetry and Tracing

**Interview Weight:** high - Observability is a Senior/Staff
differentiator. Tested for distributed tracing integration.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus OpenTelemetry (quarkus-opentelemetry) auto-instruments
> HTTP requests, database calls, Kafka messages, and
> outgoing REST client calls. Each request gets a trace
> ID propagated through W3C Trace Context headers.
> Spans are exported to a collector (Jaeger, Zipkin,
> OTLP). Inject Tracer to create custom spans. Zero code
> change needed for HTTP tracing - auto-instrumentation
> covers the common case.

**3 minutes (Senior):**

> Auto-instrumented:
>
> HTTP server requests:
>   Every incoming request = root span.
>   Trace ID in W3C traceparent header.
>
> HTTP client calls (REST client):
>   Outgoing call = child span.
>   W3C traceparent injected in outgoing headers.
>
> JDBC operations:
>   Each SQL statement = child span.
>   Query text in span attributes.
>
> Kafka consumer/producer:
>   Message send/receive = spans.
>   Context propagated in Kafka headers.
>
> Configuration:
>   quarkus.otel.exporter.otlp.endpoint=
>     http://otel-collector:4317
>   quarkus.otel.traces.sampler=traceidratio
>   quarkus.otel.traces.sampler.arg=0.1
>     (10% sampling for production)
>
> Custom spans:
>   @Inject io.opentelemetry.api.trace.Tracer tracer
>   Span span = tracer.spanBuilder("my-operation")
>     .startSpan();
>   try (Scope scope = span.makeCurrent()) {
>     // code
>   } finally { span.end(); }
>
> @WithSpan annotation:
>   @WithSpan("order-processing")
>   public void processOrder(Order order) {}
>   Auto-creates and ends the span.
>
> Baggage propagation:
>   Baggage.current().getEntryValue("tenant-id")
>   Propagated automatically in HTTP headers.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about distributed tracing
in Quarkus - how requests are tracked across services."

**(2) First principles:** "A distributed request touches
multiple services. Tracing connects the spans from all
services into one trace."

**(3) Bridge:** "OpenTelemetry is like Spring Sleuth
but vendor-neutral. Auto-instruments without code change."

---

### 💻 Code Example

```java
// Custom spans with @WithSpan
@ApplicationScoped
public class OrderService {

    @Inject
    Tracer tracer;

    // Auto-span via annotation
    @WithSpan("order.createOrder")
    public Uni<Order> createOrder(
            CreateOrderRequest req) {
        // Quarkus creates a span for this method
        // Span name: "order.createOrder"
        // Auto-ends when method returns/Uni completes
        return orderRepo.persist(Order.from(req));
    }

    // Manual span with attributes
    public Uni<BigDecimal> calculateTotal(
            Long orderId) {
        Span span = tracer
            .spanBuilder("order.calculateTotal")
            .setAttribute("order.id",
                orderId.toString())
            .startSpan();

        try (Scope scope = span.makeCurrent()) {
            return orderRepo.findById(orderId)
                .map(order -> {
                    BigDecimal total =
                        priceCalculator.calculate(
                            order);
                    span.setAttribute(
                        "order.total",
                        total.toString());
                    return total;
                })
                .onFailure()
                .invoke(e -> {
                    span.recordException(e);
                    span.setStatus(
                        StatusCode.ERROR,
                        e.getMessage());
                })
                .eventually(span::end);
        }
    }

    // Add event to current span
    public void processPayment(Order order) {
        Span currentSpan =
            Span.current();
        currentSpan.addEvent(
            "payment.initiated",
            Attributes.of(
                AttributeKey.stringKey(
                    "payment.method"),
                order.getPaymentMethod()));
    }
}

// Inject trace context into logs
@ApplicationScoped
public class OrderResource {

    private static final Logger log =
        LoggerFactory.getLogger(OrderResource.class);

    @GET
    @Path("/{id}")
    public Uni<OrderDto> findById(
            @PathParam("id") Long id) {
        // Quarkus injects trace_id, span_id into
        // MDC automatically - appears in all log lines
        // Log format: traceId=xxx spanId=yyy
        log.info("Looking up order {}", id);
        return orderService.findById(id)
            .map(OrderDto::from);
    }
}
```

```properties
# application.properties
quarkus.otel.exporter.otlp.endpoint=\
  http://otel-collector:4317
quarkus.otel.service.name=order-service

# 10% sampling in prod (high traffic)
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=0.1

# 100% sampling in dev/test
%dev.quarkus.otel.traces.sampler=alwayson

# Add service version to spans
quarkus.otel.resource.attributes=\
  service.version=${app.version},\
  deployment.environment=${quarkus.profile}
```

> **Code walkthrough:** @WithSpan on createOrder auto-creates
> a span with name "order.createOrder" and ends it when
> the Uni completes. The manual span in calculateTotal
> adds attributes (order ID, total) and records exceptions
> when the Uni fails. Quarkus auto-injects trace_id and
> span_id into the logging MDC - every log line for a
> request includes its trace ID, enabling log-to-trace
> correlation.

---

### 🎓 Answers by Seniority

**Junior:** "quarkus-opentelemetry extension + configure
OTLP endpoint. HTTP calls auto-traced. Use @WithSpan
for custom spans."

**Senior:** "Sampling strategy: 100% in dev (alwayson),
10% in prod (traceidratio) - high traffic makes 100%
sampling expensive. Trace context propagates through
Kafka headers automatically - Kafka consumer spans have
the producer span as parent. Log-to-trace correlation:
Quarkus injects trace_id to MDC; find the trace for
any log line in Jaeger."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | OpenTelemetry config, custom spans, sampling |
| Staff | 10 min | Sampling strategy, Kafka tracing, log correlation |

---

**[SENIOR] Q1 - How do you correlate Quarkus logs
with distributed traces in production?**

*Why they ask:* Production debugging workflow.

Quarkus OpenTelemetry automatically injects trace context
into the MDC (Mapped Diagnostic Context):
- trace_id: 32-hex-character W3C trace ID
- span_id: 16-hex-character span ID

Configure log format to include MDC:
```properties
quarkus.log.console.format=
  %d{HH:mm:ss.SSS} [%X{traceId}] [%X{spanId}]
  %-5p [%c{2.}] (%t) %s%e%n
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Output:
```
10:23:45.123 [4bf92f3577b34da6a3ce929d0e0e4736]
  [00f067aa0ba902b7] INFO [OrderService]
  (executor-0) Creating order 12345
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Workflow:
1. User reports error at 10:23:45.
2. Find log line in Kibana/Loki.
3. Copy trace_id from log line.
4. Paste in Jaeger search.
5. See complete distributed trace: HTTP handler → OrderService → DB → Kafka.

This eliminates "which service was the root cause?"
debugging by showing the complete call chain.

*What separates good from great:* The two-click debug
loop: log line → trace ID → Jaeger → root cause.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | OpenTelemetry config, @WithSpan, sampling. |
| Hiring Manager | Observability for production microservices. |
| Bar Raiser | Log-to-trace correlation, Kafka tracing, sampler configuration. |
| Peer Engineer | "Added trace_id to log format. P99 latency investigation time: 2 hours → 10 minutes." |

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


# Quarkus Kubernetes Operator Pattern

**Interview Weight:** high - Kubernetes operators are
an advanced pattern. Tested for Staff/Architect-level
candidates in cloud-native roles.

---

### 🎯 Model Answer

**30 seconds:**

> A Kubernetes operator is a custom controller that
> watches Custom Resource Definitions (CRDs) and reconciles
> desired state to actual state. Quarkus operator-sdk
> (quarkus-operator-sdk) implements the operator pattern
> using Java Operator SDK. Define a custom resource,
> implement a Reconciler<T> with reconcile() method.
> The SDK handles watch-loop, retry, and status management.

**3 minutes (Senior):**

> Operator components:
>
> 1. Custom Resource Definition (CRD):
>   Define in YAML or generate from Java class.
>   Your API: apiVersion: myco.com/v1, kind: Database.
>
> 2. Custom Resource (CR):
>   Instance of the CRD.
>   Spec: desired state (database name, version).
>   Status: current state (ready, error).
>
> 3. Reconciler:
>   reconcile(Database primary, Context<Database> ctx)
>   Called when CR is created/modified/deleted.
>   Must be idempotent.
>   Return: UpdateControl (requeue or done).
>
> Reconciliation loop:
>   Watch CRs for changes.
>   For each change: call reconcile().
>   Reconcile: compare desired state vs actual.
>   If different: take action (deploy pod, update config).
>   Return: UpdateControl.updateStatus() or
>     UpdateControl.noUpdate() or
>     UpdateControl.rescheduleAfter(Duration)
>
> Error handling:
>   reconcile() throws: SDK retries with backoff.
>   ErrorStatusHandler: update CR status on error.
>
> Dependency tracking:
>   @DependentResource: define child resources.
>   CRUDKubernetesDependentResource: auto-manages
>     Deployment, Service, ConfigMap.
>
> Use cases:
>   Database provisioning, cert rotation, app deployment,
>   multi-tenant configuration management.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Kubernetes operators
built with Quarkus."

**(2) First principles:** "Operator = automate what a
human operator would do for a specific application.
CRD = your custom API."

**(3) Bridge:** "Quarkus operator is like a Kubernetes
controller that manages your application's lifecycle
using Java instead of Go."

---

### 💻 Code Example

```java
// Custom Resource
@Group("myco.com")
@Version("v1")
@ShortNames("db")
public class Database extends CustomResource<
        DatabaseSpec, DatabaseStatus>
        implements Namespaced {
}

// Spec (desired state)
public class DatabaseSpec {
    private String version;   // "postgresql:16"
    private int replicas;     // 2
    private String storageClass; // "fast-ssd"
    private Map<String, String> config;
}

// Status (current state)
public class DatabaseStatus {
    private String phase;   // "Pending", "Ready", "Error"
    private String message;
    private List<String> endpoints;
    private Instant lastUpdated;
}

// Reconciler
@ControllerConfiguration(
    dependents = {
        @Dependent(type = DatabaseDeploymentDR.class),
        @Dependent(type = DatabaseServiceDR.class)
    })
public class DatabaseReconciler
        implements Reconciler<Database>,
                   ErrorStatusHandler<Database> {

    @Inject
    KubernetesClient k8sClient;

    @Override
    public UpdateControl<Database> reconcile(
            Database database,
            Context<Database> context) {

        DatabaseSpec spec = database.getSpec();

        // Check current state
        String podStatus = checkPodStatus(
            database.getMetadata().getNamespace(),
            database.getMetadata().getName());

        // Update status
        DatabaseStatus status =
            new DatabaseStatus();

        if ("Running".equals(podStatus)) {
            status.setPhase("Ready");
            status.setLastUpdated(Instant.now());
            database.setStatus(status);
            return UpdateControl.updateStatus(
                database);
        } else if ("Pending".equals(podStatus)) {
            status.setPhase("Pending");
            database.setStatus(status);
            return UpdateControl.updateStatus(database)
                .rescheduleAfter(Duration.ofSeconds(10));
        } else {
            status.setPhase("Error");
            status.setMessage("Pod not running: "
                + podStatus);
            database.setStatus(status);
            return UpdateControl.updateStatus(database)
                .rescheduleAfter(Duration.ofMinutes(1));
        }
    }

    @Override
    public ErrorStatusHandler<Database> updateErrorStatus(
            Database database,
            Context<Database> context,
            Exception e) {
        database.getStatus().setPhase("Error");
        database.getStatus().setMessage(e.getMessage());
        return database;
    }
}

// Dependent resource: manages the Deployment
public class DatabaseDeploymentDR
        extends CRUDKubernetesDependentResource<
            Deployment, Database> {

    public DatabaseDeploymentDR() {
        super(Deployment.class);
    }

    @Override
    protected Deployment desired(
            Database database,
            Context<Database> context) {
        // Return desired Deployment spec
        return new DeploymentBuilder()
            .withNewMetadata()
                .withName(database.getMetadata().getName())
                .withNamespace(database.getMetadata()
                    .getNamespace())
            .endMetadata()
            .withNewSpec()
                .withReplicas(
                    database.getSpec().getReplicas())
                // ... container spec
            .endSpec()
            .build();
    }
}
```

> **Code walkthrough:** The Reconciler is called whenever
> the Database CR changes. It checks the actual pod state
> and updates the CR's status. UpdateControl.rescheduleAfter()
> tells the SDK to call reconcile() again after the delay -
> for cases where the desired state hasn't been reached yet.
> @Dependent types (DatabaseDeploymentDR, DatabaseServiceDR)
> auto-manage child resources - the SDK creates/updates/deletes
> them as needed. CRUDKubernetesDependentResource's desired()
> method returns what the resource SHOULD look like;
> the SDK does the diff and applies changes.

---

### 🎓 Answers by Seniority

**Senior:** "Implement Reconciler<T>. reconcile() compares
desired state (spec) to actual state. Take action to
reconcile. Must be idempotent - may be called multiple times.
Return UpdateControl to signal done or reschedule."

**Staff:** "Operators encode operational knowledge:
upgrades, backups, scaling, failure recovery. The reconcile
loop is the control loop from control theory. Dependent
resources separate the what (Reconciler spec) from
the how (creating K8s primitives). Quarkus operator-sdk
adds CDI injection and hot reload to operator development."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Staff | 10 min | Operator pattern, reconcile loop, dependent resources |

---

**[STAFF] Q1 - How do you handle long-running
reconciliation without blocking the operator?**

*Why they ask:* Production operator design.

Problem: reconcile() blocks for 10 seconds waiting
for a DB pod to start. Operator misses other events.

Solution 1: rescheduleAfter pattern:
```java
public UpdateControl<Database> reconcile(
        Database db, Context<Database> ctx) {
    if (isPodReady(db)) {
        updateStatus(db, "Ready");
        return UpdateControl.updateStatus(db);
    }
    // Not ready yet, check again in 5s
    updateStatus(db, "Pending");
    return UpdateControl
        .updateStatus(db)
        .rescheduleAfter(Duration.ofSeconds(5));
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Solution 2: Event sources for watching dependent resources:
```java
// Watch pod status changes and trigger reconcile
@Override
public List<EventSource> prepareEventSources(
        EventSourceContext<Database> ctx) {
    return List.of(
        new InformerEventSource<>(
            InformerConfiguration.from(Pod.class, ctx)
                .withLabelSelector(
                    "app=database-operator")
                .build(),
            ctx));
}
// Pod changes trigger reconcile() automatically
// No polling needed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Solution 3: Reactive reconciler:
```java
// Java Operator SDK supports Uni-returning reconcile()
// if using the reactive variant
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Event source for
watching dependent resources instead of polling loops.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Operator SDK, CRD, reconcile loop. |
| Hiring Manager | Operators automate operations. |
| Bar Raiser | rescheduleAfter pattern, event sources, idempotency. |
| Peer Engineer | "Built a certificate rotation operator with Quarkus. Replaced a 200-line bash script with a 40-line Reconciler." |

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


# Quarkus Multi-Tenancy Patterns

**Interview Weight:** high - Multi-tenancy is a common
design challenge at scale. Tested for architecture
decisions.

---

### 🎯 Model Answer

**30 seconds:**

> Multi-tenancy in Quarkus can use: Schema-per-tenant
> (one database, multiple schemas, Hibernate configured
> per-request), Database-per-tenant (separate datasource
> per tenant), or Shared schema with tenant discriminator
> column. OIDC multi-tenancy: TenantResolver selects
> the OIDC configuration from the request. Dynamic
> datasource selection: QuarkusDataSourceProvider
> resolves the correct datasource for the current tenant
> context.

**3 minutes (Senior):**

> Multi-tenancy strategies:
>
> 1. Schema-per-tenant:
>   One database, multiple schemas.
>   Hibernate schema switching per request.
>   quarkus.hibernate-orm.multitenant=SCHEMA
>   SchemaResolver: returns schema name for tenant.
>   Medium isolation. Good for moderate tenant count (<500).
>
> 2. Database-per-tenant:
>   Separate datasource per tenant.
>   Highest isolation. Complex datasource management.
>   Programmatic datasource creation.
>   Good for compliance-heavy tenants.
>
> 3. Shared schema (discriminator):
>   All tenants in same tables.
>   tenant_id column on every table.
>   Hibernate Filters: auto-filter by tenant_id.
>   Lowest isolation. Highest density.
>   Risk: missing filter = data leak.
>
> Tenant identification:
>   HTTP header: X-Tenant-ID
>   JWT claim: tenant-id
>   Subdomain: tenant.company.com
>   Path: /api/tenant123/orders
>
> OIDC multi-tenancy:
>   Each tenant has its own Keycloak realm.
>   TenantResolver: maps request to OIDC config.
>   quarkus.oidc.tenant1.auth-server-url=...
>   quarkus.oidc.tenant2.auth-server-url=...

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about multi-tenancy
in Quarkus - serving multiple tenants from one application."

**(2) First principles:** "Multi-tenancy = one deployment
serves many customers. Data isolation = critical."

**(3) Bridge:** "Multi-tenancy is a cross-cutting concern:
affects DB, auth, config, routing."

---

### 💻 Code Example

```java
// Tenant context holder (thread/request-local)
@RequestScoped
public class TenantContext {
    private String tenantId;

    public String getTenantId() {
        return tenantId;
    }
    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }
}

// Tenant resolver from HTTP header
@ApplicationScoped
public class TenantRequestFilter
        implements ContainerRequestFilter {

    @Inject
    TenantContext tenantContext;

    @Override
    public void filter(
            ContainerRequestContext reqCtx) {
        String tenantId =
            reqCtx.getHeaderString("X-Tenant-ID");
        if (tenantId == null || tenantId.isBlank()) {
            reqCtx.abortWith(
                Response.status(400)
                    .entity("X-Tenant-ID required")
                    .build());
            return;
        }
        tenantContext.setTenantId(tenantId);
    }
}

// Hibernate schema multi-tenancy
@ApplicationScoped
public class TenantSchemaResolver
        implements SchemaResolver {

    @Inject
    TenantContext tenantContext;

    @Override
    public String resolveSchemaName() {
        // Map tenant ID to schema name
        // e.g., tenant123 -> tenant_123
        String tenantId =
            tenantContext.getTenantId();
        if (tenantId == null) {
            return "public";  // Default schema
        }
        return "tenant_" +
            tenantId.replaceAll("[^a-zA-Z0-9]", "");
        // Sanitize to prevent SQL injection
    }
}

// OIDC multi-tenancy
@ApplicationScoped
public class OidcTenantResolver
        implements TenantResolver {

    @Override
    public String resolve(RoutingContext ctx) {
        // Map X-Tenant-ID to OIDC tenant config
        String tenantId =
            ctx.request()
               .getHeader("X-Tenant-ID");
        return tenantId != null
            ? "tenant-" + tenantId
            : "default";
    }
}
```

```properties
# Hibernate schema multi-tenancy
quarkus.hibernate-orm.multitenant=SCHEMA

# Per-tenant OIDC config
quarkus.oidc.tenant-acme.auth-server-url=\
  https://keycloak/realms/acme
quarkus.oidc.tenant-acme.client-id=app
quarkus.oidc.tenant-globex.auth-server-url=\
  https://keycloak/realms/globex
quarkus.oidc.tenant-globex.client-id=app
```

> **Code walkthrough:** TenantContext is @RequestScoped -
> each request gets its own instance. TenantRequestFilter
> reads X-Tenant-ID and sets it on the TenantContext.
> TenantSchemaResolver returns the schema name for Hibernate
> to use - Hibernate sets the schema on the database
> connection for the request. The schema name is sanitized
> to prevent SQL injection. OidcTenantResolver maps
> the request to the correct OIDC tenant configuration.

---

### 🎓 Answers by Seniority

**Senior:** "Three strategies: schema-per-tenant (medium
isolation), database-per-tenant (max isolation), shared
schema with discriminator (highest density, lowest isolation).
Schema-per-tenant is the most common SaaS pattern."

**Staff:** "Discriminator column risk: a missing tenant_id
filter leaks all tenants' data. Hibernate's @Filter
with @FilterDef is the safest approach - enable the
filter at session start, then all queries are automatically
filtered. Still: audit queries for any HQL that bypasses
the filter."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Multi-tenancy strategies, schema resolver |
| Staff | 12 min | Strategy selection, discriminator risk, OIDC multi-tenancy |

---

**[STAFF] Q1 - How do you migrate a single-tenant
Quarkus app to schema-per-tenant multi-tenancy?**

*Why they ask:* Migration scenario requiring design thinking.

Step 1: Add TenantContext (@RequestScoped).
Identify tenant from request (header/JWT/subdomain).
Start with "default" tenant = existing data.

Step 2: Schema setup.
For each new tenant: CREATE SCHEMA tenant_X.
Run Flyway per-tenant: flyway -schemas=tenant_X migrate.
Automate with a tenant-onboarding service.

Step 3: Hibernate multi-tenancy.
Configure quarkus.hibernate-orm.multitenant=SCHEMA.
Implement SchemaResolver to return tenant schema.

Step 4: Data migration (if splitting shared data):
For existing data: copy to tenant_default schema.
Validate with row counts.

Step 5: OIDC.
Each tenant gets its own Keycloak realm.
TenantResolver maps request to realm.

Step 6: Performance.
Schema-per-tenant creates separate PostgreSQL schemas.
Same connection pool: one HikariCP pool per datasource.
Each connection can SET search_path to the tenant schema.
Tune pool size: total = per_tenant_concurrency * tenant_count.

Risk: schema count explosion. At 10,000 tenants: 10,000
schemas. PostgreSQL handles this, but schema discovery
(information_schema) slows down. Move to database-per-tenant
at that scale.

*What separates good from great:* Schema count scaling
limit and the migration to database-per-tenant threshold.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Schema resolver, multi-tenancy strategies. |
| Hiring Manager | SaaS multi-tenancy architecture. |
| Bar Raiser | Strategy selection, discriminator filter risk, migration approach. |
| Peer Engineer | "Schema-per-tenant with TenantSchemaResolver. 200 tenants, zero data leaks in 2 years." |

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



