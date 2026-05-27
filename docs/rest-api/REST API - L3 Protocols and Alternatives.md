---
layout: default
title: "REST API - L3 Protocols and Alternatives"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 6
permalink: /rest-api/l3-protocols-alternatives/
---

# GraphQL Design and Trade-offs

🎯 Interview Weight: very high - GraphQL vs REST is a classic
senior interview question. Candidates must know both sides.

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL is a query language where clients specify exactly which
> fields they need. One endpoint (POST /graphql), client-defined
> queries. Solves over-fetching (getting too much data) and
> under-fetching (N+1 round trips). Trade-off: complex caching,
> harder authorization, no HTTP semantics (all POST, all 200 OK).

**3 minutes (Senior):**
> GraphQL core benefits:
>
> No over-fetching: REST `/users/123` returns 50 fields. GraphQL
> query returns only the 8 fields the client needs. Less bandwidth,
> faster mobile.
>
> No under-fetching: REST needs 3 calls (user, orders, addresses).
> GraphQL query fetches all in one request with nested fields.
>
> Strong type system: the schema defines all types, required fields,
> and relationships. Client tooling validates queries at compile time.
>
> Self-documenting: introspection allows tools to discover the entire
> schema and generate documentation automatically.
>
> GraphQL trade-offs:
>
> No HTTP caching: all requests are POST to `/graphql`. CDNs cannot
> cache POST. Work-around: persisted queries (pre-register queries,
> GET /graphql?operationId=GetUser). Expensive for read-heavy public APIs.
>
> N+1 database problem: `users { orders { product { name }}}` executes
> N+1 queries without DataLoader. Every user triggers a separate
> orders query. Mitigation: DataLoader (batches and deduplicates
> database calls per request).
>
> Authorization complexity: field-level authorization is complex.
> REST: protect the endpoint. GraphQL: protect each field and
> object type separately. GraphQL Shield or similar library needed.
>
> Query complexity attacks: a deeply nested query can exhaust
> server resources. Mitigate with depth limits (max 10 levels),
> complexity scoring, and persisted queries for public APIs.
>
> When to use REST vs GraphQL: public APIs (REST - caching, stability,
> standard), internal APIs with multiple client types (GraphQL -
> clients specify their own data needs), mobile APIs where bandwidth
> is a constraint (GraphQL - exact fields), API with well-known
> access patterns (REST - easier to cache and optimize).

**Blank Mind Recovery:**

**(1) Restate:** "GraphQL lets clients define what data they need.
REST returns a fixed response. When is each the right choice?"

**(2) First principles:** "REST is optimized for the server (define
what the endpoint returns). GraphQL is optimized for the client
(client defines what it needs). Both have costs and benefits."

---

### 💻 Code Example

**GOOD - DataLoader pattern for N+1 prevention:**

```java
// Without DataLoader: N+1 queries
// users { orders } - 1 query for users + N for orders

// WITH DataLoader: batch query per request

@Component
public class OrderDataLoader implements
    BatchLoader<String, List<Order>> {

    private final OrderRepository orderRepo;

    // Called ONCE with ALL userIds collected in one request
    @Override
    public CompletionStage<List<List<Order>>>
        load(List<String> userIds) {

        // ONE query for all users' orders
        Map<String, List<Order>> ordersByUser =
            orderRepo.findByUserIds(userIds)
                .stream()
                .collect(groupingBy(Order::getUserId));

        // Return in same order as input userIds
        return CompletableFuture.supplyAsync(
            () -> userIds.stream()
                .map(id -> ordersByUser.getOrDefault(
                    id, List.of()
                ))
                .collect(toList())
        );
    }
}

// GraphQL resolver using DataLoader
@Component
public class UserResolver implements
    GraphQLResolver<User> {

    @Autowired
    private DataLoader<String, List<Order>> orderLoader;

    // Called for each user, but DataLoader batches
    // all calls into ONE database query
    public CompletableFuture<List<Order>> orders(User user) {
        return orderLoader.load(user.getId());
        // DataLoader collects all user IDs from the request
        // then calls OrderDataLoader.load(allUserIds) ONCE
    }
}
```

> **Code walkthrough:** Without DataLoader, resolving orders
> for 100 users executes 100 separate database queries (N+1).
> With DataLoader, all 100 `orderLoader.load(userId)` calls
> during one GraphQL request are batched: DataLoader collects
> them, calls `OrderDataLoader.load(allUserIds)` once with all
> 100 IDs, and distributes results back. The database query
> is `SELECT * FROM orders WHERE user_id IN (?, ?, ...)` with
> 100 parameters - one query vs 100. The `CompletableFuture`
> return type allows DataLoader to hold the promise and fulfill
> it after batching.

---

### ⚖️ Comparison Table

| | REST | GraphQL |
|--|------|---------|
| Caching | Native HTTP (CDN) | Requires persisted queries |
| Over-fetching | Yes (fixed response) | No (client specifies fields) |
| Under-fetching | Yes (multiple calls) | No (nested queries) |
| Schema | Implicit (docs only) | Explicit + introspection |
| Learning curve | Low | Medium-High |
| Authorization | Per-endpoint | Per-field (complex) |
| Best for | Public APIs, well-known patterns | Internal, multi-client |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GraphQL uses one endpoint where clients specify what fields they
> need. It solves over-fetching and N+1 round trips. DataLoader
> is required to prevent N+1 database queries in resolvers. REST
> is better for public APIs because of HTTP caching.

---

**Senior / Staff (5+ years):**
> I use GraphQL for internal APIs where multiple clients (mobile,
> web, partner) have different data needs. The single schema is a
> governance asset: it is the canonical data model. For public APIs,
> I use REST because HTTP caching is a significant operational
> advantage (CDN hit rates of 80%+ for catalog APIs), and
> GraphQL's caching story (persisted queries) adds operational
> complexity. The decision is mostly about who controls the data
> shape: if the server should control it (versioned, stable
> contracts), use REST. If clients should control it (multiple
> clients with different needs), use GraphQL.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | What GraphQL is + over/under-fetching |
| Mid | 5 min | N+1 + DataLoader + trade-offs |
| Senior | 8 min | When to use each + auth complexity + caching |

---

---

# gRPC and Protocol Buffers

🎯 Interview Weight: very high - gRPC is the standard for
internal microservice communication. Tested heavily in
system design rounds.

---

### 🎯 Model Answer

**30 seconds:**
> gRPC is a high-performance RPC framework using Protocol Buffers
> (binary serialization) and HTTP/2. 3-10x faster than REST+JSON
> for the same data due to binary encoding and HTTP/2 multiplexing.
> Used for internal service-to-service communication. Not suitable
> for browser-facing APIs without grpc-web.

**3 minutes (Senior):**
> gRPC advantages over REST+JSON:
>
> Protocol Buffers (protobuf): binary encoding, schema-enforced
> (`.proto` file), ~3-10x smaller payload than JSON, faster to
> serialize/deserialize. Schema evolution is structured: adding
> new fields with new numbers is backward-compatible.
>
> HTTP/2 multiplexing: multiple concurrent RPC calls on a single
> connection (no TCP connection overhead per request). Bidirectional
> streaming: server-streaming (server pushes updates), client-streaming
> (client uploads a stream), bidirectional (real-time chat).
>
> Type safety: the `.proto` file generates type-safe client and
> server code in any language. A type change in the schema causes
> compilation failures in all consumers.
>
> gRPC trade-offs:
>
> Not browser-native: browsers cannot send HTTP/2 binary frames
> directly. Requires grpc-web (a proxy layer). For browser APIs,
> REST is still standard.
>
> Not human-readable: protobuf binary cannot be inspected with curl.
> Requires `grpcurl` or Postman gRPC support.
>
> Schema coupling: all services must share the `.proto` definition.
> Schema changes must be backward-compatible (never change field
> numbers, only add new ones). This is a tighter contract than REST.
>
> When to use gRPC: internal microservice calls (performance matters,
> browser not involved), streaming (real-time data, bidirectional),
> polyglot systems (gRPC generates clients for 10+ languages from
> one `.proto` file).

**Blank Mind Recovery:**

**(1) Restate:** "gRPC is a fast RPC framework using binary protobuf
and HTTP/2, used for internal services."

**(2) First principles:** "JSON is text (verbose, slow to parse).
Protobuf is binary (compact, fast). HTTP/2 multiplexes (one
connection, many concurrent calls). Together: fast internal APIs."

---

### 💻 Code Example

**Protocol Buffers definition + Java implementation:**

```protobuf
// order_service.proto
syntax = "proto3";
package com.example.order.v1;

service OrderService {
  // Unary RPC: one request, one response
  rpc GetOrder (GetOrderRequest)
    returns (OrderResponse);

  // Server streaming: one request, many responses
  rpc WatchOrderStatus (WatchRequest)
    returns (stream OrderStatusUpdate);

  // Bidirectional streaming: real-time order tracking
  rpc StreamOrderEvents (stream OrderEventRequest)
    returns (stream OrderEvent);
}

message GetOrderRequest {
  string order_id = 1;  // Field number 1
  string user_id = 2;   // Field number 2
}

message OrderResponse {
  string id = 1;
  string status = 2;
  repeated LineItem items = 3;
  int64 total_cents = 4;
  int64 created_at_epoch = 5;
}

message LineItem {
  string product_id = 1;
  int32 quantity = 2;
  int64 price_cents = 3;
}
```

```java
// gRPC server implementation
@GrpcService
public class OrderServiceGrpc
    extends OrderServiceGrpc.OrderServiceImplBase {

    private final OrderService orderService;

    @Override
    public void getOrder(
        GetOrderRequest request,
        StreamObserver<OrderResponse> observer
    ) {
        try {
            Order order = orderService.findById(
                request.getOrderId()
            );
            // Authorization check
            if (!order.getUserId().equals(request.getUserId())) {
                observer.onError(Status.PERMISSION_DENIED
                    .withDescription("Access denied")
                    .asRuntimeException());
                return;
            }

            observer.onNext(toProto(order));
            observer.onCompleted();
        } catch (OrderNotFoundException e) {
            observer.onError(Status.NOT_FOUND
                .withDescription("Order not found: " +
                    request.getOrderId())
                .asRuntimeException());
        }
    }

    // Server streaming: push status updates until terminal
    @Override
    public void watchOrderStatus(
        WatchRequest request,
        StreamObserver<OrderStatusUpdate> observer
    ) {
        // Subscribe to order status changes (e.g., Kafka)
        orderStatusSubscriber.subscribe(
            request.getOrderId(),
            update -> {
                observer.onNext(update);
                // Complete stream on terminal status
                if (update.getStatus().isTerminal()) {
                    observer.onCompleted();
                }
            }
        );
    }
}
```

> **Code walkthrough:** The `.proto` file defines the gRPC service
> with three RPC types. Field numbers (`= 1`, `= 2`) are the wire
> protocol identifiers - they NEVER change (changing a field number
> breaks all clients). Adding a new field uses a new number.
> The Java server extends the generated base class. Error handling
> uses gRPC status codes (`NOT_FOUND`, `PERMISSION_DENIED`) which
> map to HTTP status codes in REST-gRPC transcoding. Server streaming
> (`watchOrderStatus`) pushes status updates to the client as they
> arrive - the client holds the stream open until the order is
> in a terminal state. This would require polling in REST.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> gRPC uses Protocol Buffers (binary, schema-enforced) over HTTP/2.
> Faster than REST+JSON. Used for service-to-service communication.
> Requires grpc-web for browser access. The `.proto` file defines
> the contract and generates client/server code.

---

**Senior / Staff (5+ years):**
> gRPC schema evolution requires discipline: field numbers are
> permanent (changing breaks backward compatibility). The rule:
> never delete or renumber a field, only add new numbered fields.
> Use a schema registry (Buf.build) to enforce compatibility rules
> in CI. For gRPC at scale: use gRPC load balancing at the application
> layer (not TCP load balancer), because HTTP/2 connection
> reuse means a TCP load balancer sees one connection per client,
> and one backend gets all the traffic.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | What gRPC is + protobuf + HTTP/2 |
| Mid | 5 min | vs REST trade-offs + when to use |
| Senior | 7 min | Schema evolution + load balancing + streaming |

---

---

# HTTP/2 and HTTP/3 Features

🎯 Interview Weight: medium-high - HTTP/2 features are tested
when discussing API performance. HTTP/3 is increasingly relevant.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP/2 adds multiplexing (multiple requests over one TCP connection),
> header compression (HPACK), and server push. HTTP/3 replaces TCP
> with QUIC (UDP-based), eliminating head-of-line blocking and
> improving performance on lossy networks (mobile). Both are
> transparent to REST API design - existing APIs benefit without
> code changes.

**3 minutes (Senior):**
> HTTP/1.1 problems HTTP/2 solves:
>
> Head-of-line blocking: HTTP/1.1 can only process one request
> per TCP connection at a time. To achieve parallelism, browsers
> open 6 connections per domain. HTTP/2 multiplexing: many requests
> over one TCP connection, simultaneously. Eliminates connection
> overhead.
>
> Header verbosity: HTTP/1.1 headers are plain text, repeated in
> full on every request. HTTP/2 HPACK compression: headers are
> compressed using a shared Huffman table and delta-encoded
> (only changes sent). Authorization header is sent once and
> subsequent requests send only a reference.
>
> Server push: the server can push resources the client has not
> yet requested (e.g., push the CSS file when the HTML is requested).
> In practice, rarely used in REST APIs.
>
> HTTP/2 implications for REST API design:
> - Request multiplexing makes the N+1 HTTP call less severe
>   (concurrent requests on one connection are cheap)
> - Header compression means setting many headers is less costly
> - Connection reuse is important: HTTP/2 degrades to HTTP/1.1
>   if TLS is not used (h2 requires HTTPS)
>
> HTTP/3 (QUIC):
> TCP head-of-line blocking: HTTP/2 multiplexes streams but
> they all share one TCP connection. TCP packet loss causes ALL
> streams to stall (TCP retransmission before any stream can
> proceed). QUIC uses UDP with stream-level reliability:
> packet loss stalls only the affected stream. HTTP/3 performs
> significantly better on lossy networks (mobile, high latency).
> Zero-RTT connection: QUIC can resume sessions with 0 round trips
> on reconnect (TLS 1.3 session resumption baked in).

**Blank Mind Recovery:**

**(1) Restate:** "HTTP/2 and HTTP/3 improve transport performance.
What changes and what stays the same for REST APIs?"

**(2) First principles:** "REST API semantics are unchanged.
HTTP/2 and /3 are transport optimizations: same methods,
same status codes, same headers. The network layer works faster."

---

### 💻 Code Example

**HTTP/2 verification and configuration in Spring Boot:**

```java
// Spring Boot: enable HTTP/2 in application.properties
// server.http2.enabled=true
// (requires HTTPS in production)

// Verify HTTP/2 in tests
@SpringBootTest(webEnvironment =
    SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
    "server.http2.enabled=true",
    "server.ssl.enabled=true"
})
class Http2Test {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void shouldUseHttp2() {
        // Spring RestTemplate 6.x supports HTTP/2
        var response = restTemplate.getForEntity(
            "/api/v1/products", String.class
        );
        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.OK);
    }
}

// Monitor HTTP/2 stream usage in production
// In curl:
// curl -v --http2 https://api.example.com/products
// Look for: "HTTP/2 200" in response

// In Nginx: check http2 is enabled in config
// server {
//     listen 443 ssl http2;
//     ...
// }
```

**Demonstrating multiplexing benefit:**

```java
// With HTTP/1.1: sequential calls (limited connections)
// With HTTP/2: truly concurrent on one connection

@Service
public class ParallelServiceCaller {

    private final WebClient webClient;

    // These three calls run TRULY in parallel on HTTP/2
    // (same connection, different streams)
    public AggregatedResponse fetchAll(String userId) {
        Mono<OrderSummary> orders = webClient.get()
            .uri("/api/v1/orders?userId=" + userId)
            .retrieve()
            .bodyToMono(OrderSummary.class);

        Mono<CustomerProfile> profile = webClient.get()
            .uri("/api/v1/customers/" + userId)
            .retrieve()
            .bodyToMono(CustomerProfile.class);

        Mono<List<Notification>> notifications = webClient.get()
            .uri("/api/v1/notifications?userId=" + userId)
            .retrieve()
            .bodyToFlux(Notification.class)
            .collectList();

        // Zip waits for all three (parallel, not sequential)
        return Mono.zip(orders, profile, notifications)
            .map(tuple -> new AggregatedResponse(
                tuple.getT1(),
                tuple.getT2(),
                tuple.getT3()
            ))
            .block();
    }
}
```

> **Code walkthrough:** The Spring WebClient `Mono.zip` fires
> all three requests simultaneously. With HTTP/2, all three
> requests travel over a single TCP connection as separate streams,
> with no connection setup overhead. The server processes them
> concurrently and responses arrive as each completes. With HTTP/1.1,
> each request would require a separate connection from the pool
> (or queue if the pool is exhausted). HTTP/2 multiplexing makes
> BFF-style parallel aggregation significantly faster and cheaper.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HTTP/2 adds multiplexing (multiple requests on one connection),
> header compression, and server push. HTTP/3 uses QUIC (UDP-based)
> for better performance on mobile. REST APIs benefit automatically
> when running over HTTP/2 without code changes.

---

**Senior / Staff (5+ years):**
> HTTP/2 load balancing is a common production gotcha: Layer 4
> (TCP) load balancers see only one TCP connection per client.
> All requests from a client go to the same backend. HTTP/2
> multiplexing defeats TCP-level load balancing. Solution: use
> Layer 7 (HTTP) load balancing that routes individual HTTP/2
> streams (not connections) to different backends. NGINX Plus,
> Envoy, and HAProxy support HTTP/2 stream-level load balancing.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | HTTP/2 multiplexing + header compression |
| Mid | 4 min | HTTP/3 QUIC + performance implications |
| Senior | 6 min | Load balancing with HTTP/2 + practical trade-offs |

---

---

# API Contracts and Consumer-Driven Testing

🎯 Interview Weight: high - Contract testing prevents integration
failures in microservices. Tested in senior/staff interviews.

---

### 🎯 Model Answer

**30 seconds:**
> API contracts formally define the interface between services.
> Consumer-driven contract testing (Pact) lets consumers define
> what they need and verifies the provider meets those expectations.
> This prevents "it works in isolation but breaks in integration"
> failures.

**3 minutes (Senior):**
> Contract testing fills the gap between unit tests (fast, isolated)
> and integration tests (slow, flaky, require all services running).
>
> Consumer-driven contract testing with Pact:
>
> 1. Consumer defines the contract: what requests it makes and
>    what response format it expects. Pact stores this as a
>    `.json` contract file.
>
> 2. Consumer test: runs against a Pact mock server. The consumer
>    code calls the mock server; Pact verifies the calls match
>    the defined interactions. Fast, no real service needed.
>
> 3. Provider test: the real provider service is tested against
>    all consumer contracts. The provider test replays each
>    consumer's interactions and verifies the provider response
>    matches the contract. Fails if the provider breaks a consumer.
>
> 4. Pact Broker: central store for contracts. CI/CD pipelines
>    check "can I deploy?" - is the new provider version compatible
>    with all registered consumer contracts?
>
> OpenAPI contract testing (Schemathesis, Dredd): validates that
> the server implementation matches the OpenAPI spec. Different
> from Pact: tests spec compliance, not consumer-specific contracts.
>
> Benefits: (1) find integration bugs without running all services,
> (2) consumers document their actual dependencies (not assumed),
> (3) providers know exactly what consumers use (and can safely
> remove unused fields).

**Blank Mind Recovery:**

**(1) Restate:** "Contract testing verifies that service A's
expectations of service B's API are actually met by service B."

**(2) First principles:** "Integration tests are slow and flaky.
Contract tests extract the contract (expectations) from both sides
and test them independently."

---

### 💻 Code Example

**Pact consumer test (Spring Boot + Pact JVM):**

```java
// Consumer test: Order Service consuming Customer Service

@SpringBootTest
@ExtendWith(PactConsumerTestExt.class)
@PactTestFor(providerName = "customer-service")
class OrderServiceCustomerContractTest {

    // Define what the consumer EXPECTS from the provider
    @Pact(consumer = "order-service")
    public RequestResponsePact createPact(
        PactDslWithProvider builder
    ) {
        return builder
            .given("Customer 123 exists")
            .uponReceiving("GET customer by ID")
                .method("GET")
                .path("/api/v1/customers/123")
                .headers("Authorization",
                    "Bearer test-token")
            .willRespondWith()
                .status(200)
                .headers(Map.of(
                    "Content-Type", "application/json"
                ))
                .body(newJsonBody(body -> {
                    // Consumer only needs these 3 fields
                    body.stringType("id", "123");
                    body.stringType("name", "Alice");
                    body.stringType("email",
                        "alice@example.com");
                    // Provider can return MORE fields - fine
                    // Provider MUST return THESE fields - tested
                }).build())
            .toPact();
    }

    @Test
    @PactTestFor(pactMethod = "createPact")
    void orderServiceCanFetchCustomer(
        MockServer mockServer
    ) {
        // Configure customer client to use Pact mock server
        CustomerClient client = new CustomerClient(
            mockServer.getUrl()
        );

        // Call the real consumer code
        Customer customer = client.findById("123");

        // Verify consumer can parse the response
        assertThat(customer.getId()).isEqualTo("123");
        assertThat(customer.getName()).isEqualTo("Alice");
    }
}
```

```java
// Provider test: Customer Service verifying all contracts
// Run against the REAL customer-service

@SpringBootTest(webEnvironment = RANDOM_PORT)
@Provider("customer-service")
@PactBroker(url = "${pact.broker.url}")
class CustomerServicePactVerificationTest {

    @TestTarget
    public final Target target =
        new SpringBootHttpTarget();

    // Provide test data matching each "given" state
    @State("Customer 123 exists")
    public void customerExists() {
        when(customerRepo.findById("123"))
            .thenReturn(Optional.of(
                new Customer("123", "Alice",
                    "alice@example.com", "GOLD")
            ));
    }
}
```

> **Code walkthrough:** The consumer test defines the contract:
> when the consumer calls `GET /api/v1/customers/123`, it expects
> a 200 with `id`, `name`, and `email` fields. Pact creates a mock
> server that responds with this exact format. The consumer code
> is tested against the mock - if the `CustomerClient` fails to
> parse the response, the test fails. The provider test loads
> all registered consumer contracts from the Pact Broker and
> replays them against the real `customer-service`. The `@State("Customer 123 exists")`
> sets up test data for this scenario. If `customer-service` removes
> the `email` field, the provider test fails - before any deployment
> to a shared environment.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Contract testing validates that a service's API responses match
> what consumers expect. Pact generates mock servers for consumers
> and runs the real contract against providers. Prevents integration
> failures from API changes.

---

**Senior / Staff (5+ years):**
> Pact's "can I deploy?" workflow is the key governance mechanism.
> Before a provider deploys a new version, it checks: are all
> consumer contracts still passing? If a consumer contracts-tests
> against an old version of the provider response, the new version
> cannot deploy until the consumer updates their contract or the
> provider maintains backward compatibility. This reverses the
> traditional "consumers update when providers change" model.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What contract testing is + why needed |
| Mid | 5 min | Pact consumer/provider test structure |
| Senior | 7 min | "Can I deploy?" governance + schema evolution |

---

---

# Event-Driven APIs and Webhooks

🎯 Interview Weight: high - Webhooks are the event notification
standard for external APIs. Used by Stripe, GitHub, Twilio.

---

### 🎯 Model Answer

**30 seconds:**
> Event-driven APIs push notifications to clients rather than
> waiting for clients to poll. Webhooks are HTTP callbacks:
> the server POSTs to a client-registered URL when an event
> occurs. Key concerns: signature verification (HMAC-SHA256),
> delivery reliability (retry with exponential backoff),
> and idempotency (same event delivered twice must be processed once).

**3 minutes (Senior):**
> REST polling vs webhooks vs SSE vs WebSocket:
>
> Polling: client repeatedly asks "did anything change?"
> Simple but wastes requests when nothing changes. Introduces
> latency (at most 1 polling interval per event).
>
> Webhooks: server pushes events to client URL. No polling
> waste. Requires client to expose an inbound HTTP endpoint.
> Server must implement reliable delivery (retry on failure).
>
> Server-Sent Events (SSE): server pushes events over a long-lived
> HTTP connection. One-directional (server to client). Browser-native
> (`EventSource` API). Good for live dashboards, notification feeds.
> Not suitable for bidirectional.
>
> WebSocket: full bidirectional real-time communication. Good for
> chat, live collaboration, gaming. More complex (not standard
> HTTP, requires WebSocket infrastructure).
>
> Webhook reliability requirements:
> 1. Delivery: retry with exponential backoff (15s, 1m, 5m, 30m,
>    2h, 8h, 24h). Total retry window: typically 24 hours.
> 2. Idempotency: include a unique `event_id` in the payload.
>    Consumers must deduplicate on `event_id`.
> 3. Signature: HMAC-SHA256 of the payload using a shared secret.
>    Validates the webhook is from the claimed source.
> 4. Ordering: do not guarantee ordering. Consumers must handle
>    out-of-order events (use event timestamps, not arrival order).
> 5. Timeouts: webhook delivery must complete within 10-30s.
>    Consumer must return 200 quickly, process async.

**Blank Mind Recovery:**

**(1) Restate:** "Webhooks push events to registered client URLs.
The key concerns are: did it arrive? Was it legitimate? Was it
processed exactly once?"

---

### 💻 Code Example

**GOOD - Webhook delivery with signature + retry:**

```java
// Webhook delivery service with reliability
@Service
public class WebhookDeliveryService {

    private final WebhookRepository webhookRepo;
    private final RestTemplate httpClient;

    @Value("${webhook.signing.secret}")
    private String signingSecret;

    public void deliverEvent(
        String eventId,
        String eventType,
        Object payload
    ) {
        String payloadJson = toJson(payload);
        String timestamp =
            String.valueOf(Instant.now().getEpochSecond());

        // HMAC-SHA256 signature
        String signature = computeHmac(
            signingSecret,
            timestamp + "." + payloadJson
        );

        List<WebhookEndpoint> endpoints =
            webhookRepo.findByEventType(eventType);

        for (WebhookEndpoint endpoint : endpoints) {
            deliverToEndpoint(
                endpoint.getUrl(),
                eventId,
                eventType,
                payloadJson,
                timestamp,
                signature
            );
        }
    }

    @Retryable(
        retryFor = WebhookDeliveryException.class,
        maxAttempts = 7,
        backoff = @Backoff(
            delay = 15000,     // 15s first retry
            multiplier = 4,    // 1m, 5m, 20m, 80m...
            maxDelay = 86400000 // max 24h
        )
    )
    private void deliverToEndpoint(
        String url,
        String eventId,
        String eventType,
        String payload,
        String timestamp,
        String signature
    ) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Content-Type", "application/json");
        headers.set("X-Event-Id", eventId);
        headers.set("X-Event-Type", eventType);
        headers.set("X-Timestamp", timestamp);
        headers.set(
            "X-Signature",
            "sha256=" + signature
        );

        ResponseEntity<Void> response = httpClient.exchange(
            url,
            HttpMethod.POST,
            new HttpEntity<>(payload, headers),
            Void.class
        );

        if (!response.getStatusCode().is2xxSuccessful()) {
            // Trigger retry
            throw new WebhookDeliveryException(
                "Non-2xx: " + response.getStatusCode()
            );
        }
    }
}

// Webhook consumer: verify signature + idempotency
@RestController
public class WebhookReceiver {

    private final ProcessedEventRepository processedEvents;

    @PostMapping("/webhooks/payments")
    public ResponseEntity<Void> receiveWebhook(
        @RequestBody String payload,
        @RequestHeader("X-Signature") String signature,
        @RequestHeader("X-Timestamp") String timestamp,
        @RequestHeader("X-Event-Id") String eventId
    ) {
        // 1. Verify signature FIRST
        String expectedSig = "sha256=" + computeHmac(
            webhookSecret,
            timestamp + "." + payload
        );
        if (!MessageDigest.isEqual(
            expectedSig.getBytes(),
            signature.getBytes()
        )) {
            return ResponseEntity.status(401).build();
        }

        // 2. Check timestamp (reject if > 5 minutes old)
        long ts = Long.parseLong(timestamp);
        if (Instant.now().getEpochSecond() - ts > 300) {
            return ResponseEntity.status(400).build();
        }

        // 3. Idempotency: check if already processed
        if (processedEvents.exists(eventId)) {
            return ResponseEntity.ok().build(); // 200 = success
        }

        // 4. Return 200 IMMEDIATELY, process async
        eventProcessor.processAsync(payload);
        processedEvents.save(eventId);

        return ResponseEntity.ok().build();
    }
}
```

> **Code walkthrough:** Signature verification uses constant-time
> comparison (`MessageDigest.isEqual`) to prevent timing attacks
> (a naive `equals` check can leak signature length information
> to a timing attacker). The timestamp check (reject events >5
> minutes old) prevents replay attacks - an attacker cannot capture
> a valid webhook and replay it later. Idempotency uses an
> `event_id` store - the same event delivered twice returns 200
> but is only processed once. Returning 200 immediately and
> processing asynchronously is critical: webhook delivery has a
> 30-second timeout; slow processing would cause delivery retries
> (duplicate processing).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Webhooks are HTTP callbacks. The server POSTs to the client's
> registered URL when an event occurs. The client verifies the
> `X-Signature` header (HMAC-SHA256) to confirm the webhook
> is from the expected source.

---

**Senior / Staff (5+ years):**
> Webhook reliability is often treated as an afterthought and
> breaks in production. The failures I have seen: (1) consumer
> endpoint takes 30 seconds to process (delivery times out,
> duplicate delivery on retry - consumer processes twice), (2)
> consumer goes down for 2 hours (missed events, no replay),
> (3) no idempotency (order created twice from duplicate delivery).
> The fix: consumer returns 200 immediately, processes async,
> deduplicates on event ID. Provider stores undelivered events
> for 24-hour replay window.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What webhooks are + use cases |
| Mid | 4 min | Signature verification + reliability |
| Senior | 7 min | Replay + idempotency + vs polling/SSE/WebSocket |

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Webhook implementation + retry logic |
| System Design | Event-driven architecture + protocol comparison |
| Security | HMAC verification + replay prevention |
