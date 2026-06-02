---
layout: default
title: "Distributed Systems - L2 Communication Patterns"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 5
permalink: /distributed-systems/l2-communication-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Remote Procedure Call and gRPC](#remote-procedure-call-and-grpc) | medium |
| 2 | [Message Passing and Event-Driven Architecture](#message-passing-and-event-driven-architecture) | medium |

---

# Remote Procedure Call and gRPC

**TL;DR:** Remote Procedure Call (RPC) makes a network call look like
a local function call. gRPC is Google's high-performance RPC framework
using Protocol Buffers (binary serialization) over HTTP/2 (multiplexed
streams). gRPC is 5-10x more compact than JSON/REST and supports
streaming (server push, bidirectional). The trade-offs: binary format
is not human-readable, HTTP/2 is harder to inspect than HTTP/1.1,
and strong schema coupling via .proto files.

---

### 🎯 Model Answer

**30 seconds:**
> RPC lets you call a function on another machine as if it were local.
> gRPC is the modern implementation: uses Protocol Buffers for binary
> serialization (compact, fast), HTTP/2 for transport (multiplexed
> streams, header compression). It is 5-10x more efficient than REST+JSON.
> The cost: schema coupling (.proto files must be shared), binary
> format is not human-readable, harder to debug than JSON.

**3 minutes:**
> RPC abstracts network communication: instead of writing
> `httpClient.post("/order", orderJson)`, you write `orderService.create(request)`
> and the RPC framework handles serialization, transport, and
> deserialization. gRPC, released by Google in 2015, made RPC the
> standard for internal service communication.
>
> Why gRPC over REST+JSON: (1) Protobuf is binary - a JSON message
> of 1000 bytes might be 200 bytes as Protobuf. (2) HTTP/2 multiplexes
> multiple requests over one TCP connection (no head-of-line blocking,
> no connection-per-request overhead). (3) Strongly typed schema in
> .proto files serves as both documentation and code generation source.
> (4) Streaming: server-side streaming (server pushes a stream of
> responses), client-side streaming, and bidirectional streaming
> are native.
>
> Trade-offs: the schema coupling is double-edged - you get type safety
> and generated client code, but every API change requires coordination
> (proto changes, regenerating clients). Debugging: you cannot easily
> inspect gRPC traffic with `curl` or a browser. Requires grpcurl or
> Postman gRPC. Browser support is limited (gRPC-Web is a workaround).

**Blank Mind Recovery:**

**(1) Restate:** "gRPC - the modern RPC framework using Protocol Buffers
and HTTP/2 for efficient service communication."

**(2) First principles:** "Services need to call each other. REST+JSON
is human-readable but inefficient. Binary protocols are compact but
need schema agreement. gRPC combines binary efficiency with code
generation from a schema."

**(3) Bridge:** "Like the difference between sending a spreadsheet
as CSV (human-readable, larger file) vs a binary Excel file (smaller,
faster to parse, but needs Excel to open). gRPC is the binary format
for service communication."

---

### 📘 Concept Explanation

**What it is:**
gRPC is an open-source RPC framework from Google. It uses Protocol
Buffers (Protobuf) for serialization and HTTP/2 as the transport
protocol. Services are defined in .proto files; client and server
stubs are code-generated.

**The problem it solves:**
HTTP/1.1 + JSON for internal service communication creates overhead:
text parsing, large payload sizes, per-request connection overhead.
At millions of RPC calls per second, this overhead is measurable.
gRPC reduces payload size 5-10x and reduces transport overhead via
HTTP/2 multiplexing.

**How it works:**

```
1. Define service contract (.proto file):
   service OrderService {
     rpc CreateOrder (CreateOrderRequest)
         returns (CreateOrderResponse);
   }

2. Generate client+server stubs from .proto

3. Client calls stub method (looks like local call):
   OrderService.BlockingStub stub = ...;
   CreateOrderResponse resp =
       stub.createOrder(request);

4. Stub serializes request to Protobuf binary

5. HTTP/2 transport sends binary over the wire

6. Server deserializes, calls handler

7. Handler serializes response, sends back
```

> **Code walkthrough:** This Remote Procedure Call and gRPC example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**HTTP/2 advantages:**

```
HTTP/1.1:
  - One request per connection (or pipelining)
  - Text-based headers (repeated, redundant)
  - Head-of-line blocking

HTTP/2:
  - Multiplexing: N requests over one connection
  - Header compression (HPACK)
  - Binary framing (efficient parsing)
  - Server push (proactive data push)
```

> **Code walkthrough:** This Remote Procedure Call and gRPC example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Streaming types:**

```
Unary:         Client sends 1, server sends 1
Server stream: Client sends 1, server sends N
Client stream: Client sends N, server sends 1
Bidirectional: Client sends N, server sends N
               (independent streams, not request-response)
```

> **Code walkthrough:** This Remote Procedure Call and gRPC example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
gRPC's schema-first approach (.proto) is both its strength and its
coupling point. It generates typed clients in 11+ languages, provides
forward/backward compatibility rules (field numbers), and serves
as the contract between producer and consumer. It is an API contract
enforced by the compiler.

**When to use it:**
- Internal service-to-service communication
- High-throughput, low-latency inter-service calls
- Streaming data (live feeds, server-push updates)
- Polyglot services needing a shared contract

**When NOT to use it:**
- Public APIs that browser clients need to call directly
  (use REST+JSON or GraphQL instead)
- When simplicity of curl/Postman debugging is important
- When the team is unfamiliar with Protobuf and schema evolution

**Alternatives:**
- REST+JSON: universal, human-readable, browser-friendly
- GraphQL: flexible query language, client-specified fields
- Apache Thrift: similar to gRPC (Facebook's earlier version)
- Avro+Kafka: schema registry for async messaging

**First-principles derivation:**
"Services communicate over networks. Networks add latency and
bandwidth cost. Minimizing per-message overhead (smaller payloads,
fewer connections) reduces both. Binary serialization + multiplexed
transport achieves this. Schema-first code generation adds type safety
and removes hand-written boilerplate."

---

### 💻 Code Example

```java
// gRPC JAVA SERVICE IMPLEMENTATION

// 1. Proto definition (orders.proto):
// service OrderService {
//   rpc CreateOrder (CreateOrderRequest)
//       returns (CreateOrderResponse);
//   rpc WatchOrderStatus (WatchRequest)
//       returns (stream OrderStatusEvent);
// }

// 2. Server implementation (generated base class)
public class OrderServiceImpl
        extends OrderServiceGrpc.OrderServiceImplBase {

    @Override
    public void createOrder(
            CreateOrderRequest request,
            StreamObserver<CreateOrderResponse>
                responseObserver) {
        // gRPC calls this handler on a thread pool
        try {
            Order order = orderService.create(
                request.getCustomerId(),
                request.getItems());
            // Unary: send one response
            responseObserver.onNext(
                CreateOrderResponse.newBuilder()
                    .setOrderId(order.getId())
                    .setStatus("CREATED")
                    .build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(
                Status.INTERNAL
                    .withDescription(e.getMessage())
                    .asRuntimeException());
        }
    }

    // Server-streaming: push status updates to client
    @Override
    public void watchOrderStatus(
            WatchRequest request,
            StreamObserver<OrderStatusEvent>
                responseObserver) {
        orderEventBus.subscribe(
            request.getOrderId(),
            event -> {
                // Each status change pushes an event
                responseObserver.onNext(
                    OrderStatusEvent.newBuilder()
                        .setStatus(event.getStatus())
                        .setTimestamp(event.getTs())
                        .build());
                if (event.isFinal()) {
                    responseObserver.onCompleted();
                }
            });
    }
}

// 3. Client usage
public class OrderClient {
    private final OrderServiceGrpc.OrderServiceBlockingStub
        stub;

    public String placeOrder(
            long customerId, List<Item> items) {
        CreateOrderResponse response = stub.createOrder(
            CreateOrderRequest.newBuilder()
                .setCustomerId(customerId)
                .addAllItems(toProto(items))
                .build());
        return response.getOrderId();
    }
}
```

> **Code walkthrough:** The server extends the generated base classice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> and overrides the handler methods. The `StreamObserver` pattern
> handles both unary (call `onNext` once then `onCompleted`) and
> streaming (call `onNext` multiple times) responses uniformly.
> Errors are signaled via `onError` with a gRPC Status code (analogous
> to HTTP status codes but richer). The server-streaming example shows
> the live update pattern: the client subscribes to order status updates
> and the server pushes events as they occur - without the client
> polling. The blocking stub is the simplest client pattern; async
> stubs exist for non-blocking patterns.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> gRPC is an RPC framework using Protocol Buffers (binary, compact)
> over HTTP/2 (multiplexed, fast). You define the service contract in
> a .proto file and generate client/server code. More efficient than
> REST+JSON for internal services. Trade-off: binary format is harder
> to debug, schema coupling means both sides must agree on .proto changes.

*Push deeper:* "gRPC supports four call types: unary (one request,
one response), server streaming, client streaming, and bidirectional.
Unary is the default. Streaming is powerful for live data."

---

**Senior / Staff:**
> In production: gRPC interceptors for cross-cutting concerns
> (distributed tracing, auth, retry logic). Schema evolution: use
> field numbers (never reuse or remove them), mark removed fields
> reserved, use oneof for optional variants. Deadlines: always set
> per-call deadlines; without them a slow downstream can block
> your thread pool indefinitely.

*Push deeper:* "Load balancing gRPC over HTTP/2 is subtler than
HTTP/1.1: most L4 load balancers only balance at connection level
(all requests on one connection to one backend). gRPC requires L7
(application-layer) load balancing - Envoy, Linkerd, or client-side
load balancing."

---

### ⚠️ Common Misconceptions

**"gRPC is only for internal services"**

Reality: gRPC-Web allows browser clients to call gRPC services via
an HTTP/1.1 proxy translation layer. Used in production at Google
and others. Limited bidirectional streaming support in browsers, but
unary and server streaming work. For most public APIs, REST is still
simpler; for browser apps needing high-frequency data, gRPC-Web or
WebSocket is an option.

**"Protobuf is not backward compatible"**

Reality: Protobuf has specific backward/forward compatibility rules.
Adding a new field (new field number): safe - old clients ignore
unknown fields. Removing a field: mark as reserved to prevent number
reuse. Changing a field type: depends on wire type compatibility.
Changing a field name: safe (names are not on the wire, only numbers).
As long as field numbers are preserved and the reserved keyword is
used, Protobuf schema evolution is safe.

---

### ⚖️ Comparison Table

| Protocol | Payload | Debug | Browser | Streaming | Schema |
|---|---|---|---|---|---|
| REST+JSON | Large | Easy (curl) | Native | No (polling/SSE) | Optional |
| gRPC | Small (~5x) | Needs tooling | grpc-web | Native 4 types | Required .proto |
| GraphQL | Medium | Good (introspect) | Native | Subscriptions | Optional |
| Thrift | Small | Moderate | No | Limited | Required .thrift |

**The deciding factor:** If the caller is a browser or an external
party: REST+JSON. If it is internal service-to-service with high
throughput: gRPC.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Connection pool exhaustion under sustained load.**

Symptom: `UNAVAILABLE` or `RESOURCE_EXHAUSTED` status codes, increasing queue depth in the gRPC channel. Diagnosis: check `grpc_client_connections` gauge and `grpc_client_calls_started` vs `grpc_client_calls_finished` counters - a growing delta means calls are not completing. Fix: tune `MaxConcurrentStreams` on the server and connection pool size on the client; add circuit breakers (gRPC interceptor pattern) to fail fast when the downstream is saturated rather than queueing indefinitely.

**Failure Mode 2: Deadline propagation not threaded through call chain.**

Symptom: upstream callers timeout while downstream services continue processing (wasted work); downstream logs show requests completing after the upstream gave up. Diagnosis: correlate request IDs across service logs - upstream logs show `DEADLINE_EXCEEDED` while downstream logs show a completed response for the same request ID. Fix: always extract the deadline from the incoming context and pass it unchanged to all downstream gRPC calls; never reset or extend the deadline inside a handler.

**Failure Mode 3: Streaming RPC half-close not handled correctly.**

Symptom: client-streaming or bidirectional streaming calls leak resources - server-side handlers never complete, goroutine/thread count grows indefinitely. Diagnosis: profile goroutine count with `pprof` or JFR; look for stream handlers that are blocked waiting for more client messages after the client closed its send channel. Fix: handle the `io.EOF` (Go) or `onCompleted` (Java) event to properly terminate the server-side handler when the client signals no more messages.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [DEBUGGING] gRPC calls between services start failing with DEADLINE_EXCEEDED after a deploy. What do you investigate?**

DEADLINE_EXCEEDED means the server is not responding within the
client's configured deadline. Root causes: (1) the deployed service
is slower due to a bug (N+1 query, missing index, increased load).
(2) the deadline is too tight for the new code path. (3) downstream
dependency of the deployed service is slower. Diagnosis: check server
latency histograms (p99) before and after deploy. Check the server-side
processing time vs the deadline. Check if the deployed service calls
any new or changed downstream service. If the server is slower: profile
the new code path. If the deadline is too tight: increase it (or fix
the slow path). Always propagate deadlines: the server should subtract
processing time from the incoming deadline before passing it to
downstream calls.

**[JUNIOR] Q2 - [MECHANISM] gRPC load is not distributed evenly across backend instances. One instance receives 80% of traffic.**

This is the HTTP/2 load balancing problem. HTTP/2 multiplexes
all requests over one TCP connection. An L4 load balancer (TCP level)
sees one connection per client and routes it to one backend for the
connection lifetime. All subsequent requests from that client go
to the same backend - no per-request balancing. Fix: (1) use an
L7 proxy (Envoy, Nginx with gRPC module) that can balance individual
gRPC streams even within one HTTP/2 connection. (2) use client-side
load balancing (client holds a list of backends, round-robins). (3)
use a service mesh (Linkerd, Istio) that handles gRPC load balancing
transparently.

#### Candidate Mistakes

**[JUNIOR] Q3 - [MECHANISM] How do you handle breaking changes in a gRPC API?**

**What NOT to say:** "Just change the .proto and redeploy."

**Say instead:** "The field number contract is the key. Never change
a field's number or type. To add new fields: assign a new field number
(never reuse old ones). To remove a field: mark it as reserved
to prevent the number from being accidentally reused by future fields.
For larger breaking changes (renaming a service, changing a method
signature significantly): introduce a new version of the service (v2)
alongside the old one. Route clients to v2 over time. Maintain v1
until all clients are migrated. Never force clients to update
simultaneously - that is a breaking deployment."

#### Questions to Ask the Interviewer

**[MID] Q4 - [MECHANISM] "Are services in the same language or polyglot? gRPC's code generation value is highest in polyglot environments."**

*Why:* Reveals whether gRPC's schema-based code generation aligns
with the actual tech stack diversity.

**[MID] Q5 - [MECHANISM] "How is load balancing implemented for gRPC services? L4 or L7?"**

*Why:* gRPC load balancing at L4 (TCP) is broken for HTTP/2 - shows
you understand the non-obvious issue.

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


# Message Passing and Event-Driven Architecture

**TL;DR:** Message passing decouples services: a sender publishes a
message to a broker without waiting for the receiver. Event-driven
architecture (EDA) extends this: services publish events when something
happens (order.placed, payment.processed), and other services react.
Benefits: temporal decoupling (sender does not wait), resilience
(receiver failure does not block sender), fanout (many subscribers,
one publisher). Costs: eventual consistency, harder to trace end-to-end,
more operational complexity.

---

### 🎯 Model Answer

**30 seconds:**
> Message passing: services communicate through a broker without
> direct coupling. The sender publishes a message and moves on; the
> receiver processes it when ready. Event-driven architecture: services
> emit events when things happen; other services react. Benefits:
> temporal decoupling, resilience, fan-out. Costs: eventual consistency,
> no immediate feedback, harder to debug.

**3 minutes:**
> In synchronous communication (REST, gRPC), the caller blocks waiting
> for the response. If the callee is slow, the caller is slow. If the
> callee is down, the caller fails. Asynchronous messaging fixes this
> by introducing a broker (Kafka, RabbitMQ, SQS). The sender publishes
> a message to the broker and immediately continues. The broker durably
> stores the message. The receiver reads and processes it at its own
> pace. Temporal decoupling: the sender and receiver do not need to
> run simultaneously.
>
> Event-driven architecture takes this further: instead of commands
> ("process this payment"), services emit facts ("payment.received.v1").
> Other services subscribe and react: inventory adjusts, confirmation
> email sends, analytics updates. The publisher does not know or care
> about the subscribers. This enables loose coupling and fan-out without
> the publisher knowing about every consumer.
>
> The trade-offs: debugging is harder (no immediate error if a consumer
> fails), the system is eventually consistent (downstream effects may
> take seconds to process), and testing requires simulating the broker
> and multiple consumers. The Outbox pattern solves the dual-write
> problem: writing to the database and publishing to the broker must
> be atomic.

**Blank Mind Recovery:**

**(1) Restate:** "Message passing and event-driven architecture -
asynchronous communication between services via a broker."

**(2) First principles:** "Two services need to coordinate. Synchronous:
one calls the other, waits. Async: one publishes a message to a
broker, the other picks it up when ready. The broker is the buffer."

**(3) Bridge:** "Like email vs a phone call. A phone call is synchronous:
you both must be available at the same time. Email is asynchronous:
send it now, they read it later. The email server is the broker."

---

### 📘 Concept Explanation

**What it is:**
Message passing: communication between processes by sending discrete
messages through an intermediary (message broker) rather than direct
calls. Event-driven architecture: a pattern where services publish
events to notify others of state changes, and subscribers react.

**The problem it solves:**
Synchronous service calls create tight temporal coupling: if Service B
is down, Service A fails too. If B is slow, A is slow. Message passing
breaks this coupling: A publishes to a broker (which absorbs the load),
B processes when available. Spike absorption: if A publishes 10,000
messages in a burst, B processes them at its own pace (backpressure).

**Message broker patterns:**

**Queue (Point-to-Point):**
```
Publisher → [Queue] → Consumer
One consumer processes each message.
Used for: task distribution, work queues.
```

> **Code walkthrough:** This Message Passing and Event-Driven Architecture exampice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Topic/Pub-Sub (Broadcast):**
```
Publisher → [Topic] → Consumer Group A
                    → Consumer Group B
                    → Consumer Group C
Each consumer group gets every message.
Used for: event fan-out, notifications.
```

> **Code walkthrough:** This Message Passing and Event-Driven Architecture example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Event log (Kafka-style):**
```
Publisher → [Partition 1] [Partition 2] [Partition 3]
                ↓               ↓               ↓
           Consumer A-1    Consumer B-1    Consumer C-1
Ordered log, retained for configurable time.
Consumers can replay from any offset.
```

> **Code walkthrough:** This Message Passing and Event-Driven Architecture exampice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The Outbox Pattern (crucial):**

```
PROBLEM: dual-write atomicity
  Step 1: UPDATE orders SET status='PLACED'
  Step 2: PUBLISH order.placed to Kafka
  If server crashes between 1 and 2:
    DB updated, event never published.
    Other services never notified.
    Data inconsistency.

SOLUTION: Outbox table
  Within one transaction:
    UPDATE orders SET status='PLACED'
    INSERT INTO outbox (event_type, payload)
        VALUES ('order.placed', ...)
  Background process reads outbox, publishes to Kafka
  Marks as published.
  Atomic because both writes are in one DB transaction.
```

> **Code walkthrough:** This Message Passing and Event-Driven Architecture example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Event schema design:**

Event-driven systems have two competing philosophies:

Thin events ("notification"): just the event type and ID.
Consumers must query the source service to get data.
Pros: always get current data. Cons: back-pressure on source service.

Fat events ("document"): include all relevant data in the payload.
Pros: consumer is self-contained. Cons: events can become large,
schema coupling to producer's data model.

**The key insight:**
Events are immutable facts about what happened. They should be named
in past tense (`order.placed`, not `place.order`). Once published,
they cannot be changed. This immutability is the foundation of
event sourcing and audit logs.

**When to use it:**
- When the sender does not need an immediate response
- Fan-out: one event must trigger many consumers
- Spike absorption: publisher bursts, consumer processes steadily
- Long-running processes: send job, process asynchronously

**When NOT to use it:**
- When you need immediate confirmation (payment authorization)
- When strict consistency is required between the write and the
  downstream effect
- When operational complexity of a broker is not justified
  (simple two-service systems with low traffic)

**Alternatives:**
- Synchronous REST/gRPC: simple, immediate feedback, tight coupling
- Outbox + background jobs: simpler than a full broker for low volume
- WebSocket/Server-Sent Events: for real-time browser push

**First-principles derivation:**
"Service A needs to tell Service B something happened. Direct call:
A waits for B. This creates coupling. Introduce a buffer (broker):
A writes to buffer, B reads from buffer. A does not wait. B processes
at its pace. Buffer also enables: multiple B instances (scale consumers),
multiple different B services (fan-out), retry on B failure (the
message stays in the buffer until B confirms processing)."

---

### 💻 Code Example


```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```

```java
// OUTBOX PATTERN: atomic DB write + event publish

// BAD: dual-write without atomicity
@Transactional
public void placeOrder(Order order) {
    orderRepository.save(order); // DB write
    // CRASH HERE: order saved, event never published
    // Inventory service never receives the event
    // Order stuck in inconsistent state forever
    kafkaTemplate.send(
        "order.placed",
        new OrderPlacedEvent(order.getId()));
}

// GOOD: Outbox pattern - single transaction
@Transactional
public void placeOrder(Order order) {
    // Both writes in one ACID transaction
    orderRepository.save(order);
    // Write event to outbox table (same DB, same tx)
    outboxRepository.save(OutboxEvent.builder()
        .eventType("order.placed")
        .aggregateId(order.getId().toString())
        .payload(serialize(new OrderPlacedEvent(
            order.getId(),
            order.getCustomerId(),
            order.getTotalAmount())))
        .createdAt(Instant.now())
        .published(false)
        .build());
    // If this method returns normally: both writes committed
    // If it throws: both are rolled back (atomicity)
}

// Background publisher (runs every second)
@Scheduled(fixedDelay = 1000)
public void publishOutboxEvents() {
    List<OutboxEvent> pending =
        outboxRepository.findByPublished(false);
    for (OutboxEvent event : pending) {
        try {
            kafkaTemplate.send(
                event.getEventType(),
                event.getPayload()).get(); // sync send
            event.setPublished(true);
            outboxRepository.save(event);
        } catch (Exception e) {
            // Will retry on next scheduled run
            log.error("Failed to publish event: {}",
                event.getId(), e);
        }
    }
}
```

> **Code walkthrough:** The BAD example has a dual-write problem: theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> database write and the Kafka publish are two separate operations with
> no atomicity guarantee. A crash between them leaves the system in an
> inconsistent state. The GOOD example uses the Outbox pattern: both
> the business write and the event record are written in a single
> database transaction (atomicity). The background scheduler reads
> unpublished events and sends them to Kafka. At-least-once delivery:
> if the scheduler crashes after Kafka publish but before marking
> published, it will republish on the next run. Consumers must be
> idempotent to handle duplicates.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Message passing: services communicate through a broker, not directly.
> Sender publishes a message and moves on; receiver processes when
> ready. Event-driven: services emit events (order.placed), others
> react. Benefits: decoupling, fan-out, resilience. Costs: eventual
> consistency, harder to trace end-to-end.

*Push deeper:* "The Outbox Pattern solves the hardest problem in
event-driven systems: ensuring a database write and the corresponding
event publish are atomic."

---

**Senior / Staff:**
> In production: schema registry (Confluent Schema Registry) for
> Avro or Protobuf schema evolution of Kafka events - prevents
> producer from publishing events consumers cannot parse. Dead-letter
> queues: messages that fail processing go to a DLQ rather than
> blocking the consumer. Consumer idempotency: at-least-once delivery
> means consumers may receive duplicates - they must handle them.

*Push deeper:* "Consumer group lag monitoring: if consumers fall
behind, events accumulate in the broker. Lag > N minutes = consumers
cannot keep up with production rate. Horizontal scaling of consumers
(add consumer instances to the group) is the fix - up to the number
of partitions."

---

### ⚠️ Common Misconceptions

**"Event-driven means always use Kafka"**

Reality: Kafka is appropriate for high-throughput, ordered, replayable
event logs. For simple task queues with low volume: SQS, RabbitMQ,
or even a database-backed job queue is simpler and cheaper. Kafka
has real operational overhead: managing partitions, consumer groups,
offset management, ZooKeeper/KRaft. Do not adopt Kafka until you
have a clear need for its specific features (replay, high throughput,
ordered processing within partitions).

**"Async messaging is always more resilient than sync"**

Reality: async messaging moves the failure mode rather than eliminating
it. With synchronous calls: Service A fails if Service B is down -
immediately visible. With async messaging: Service A succeeds, but
if Service B crashes, the event sits in the broker unprocessed.
The consumer failure is less visible (may go undetected for hours
without DLQ monitoring). Async can hide failures; you need comprehensive
consumer lag and DLQ monitoring to detect them.

---

### ⚖️ Comparison Table

| Pattern | Coupling | Consistency | Feedback | Use When |
|---|---|---|---|---|
| Sync REST/gRPC | Tight | Immediate | Instant | Need response immediately |
| Async queue | Loose | Eventual | None | Fire-and-forget tasks |
| Pub/Sub topic | Loose | Eventual | None | Fan-out to many consumers |
| Kafka event log | Loose | Eventual + replay | None | Ordered events, replay needed |
| Outbox+event | Loose | Atomic+eventual | None | DB write + event atomically |

**The deciding factor:** Does the caller need immediate confirmation
of downstream processing? If yes: synchronous. If the downstream
effect can happen asynchronously: messaging.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Consumer lag grows continuously - consumer cannot keep up with producer.**

Symptom: queue depth or consumer lag metric shows steady increase over time; messages accumulate faster than they are processed. Diagnosis: compare producer throughput vs consumer processing rate - run `kafka-consumer-groups.sh --describe` or monitor the `consumer_lag` metric per partition; profile consumer processing time. Fix: scale consumer group instances (up to partition count), optimize the consumer's critical path (reduce synchronous I/O in the processing loop), or implement async processing with a bounded thread pool inside the consumer.

**Failure Mode 2: Event ordering violated due to multi-partition or multi-consumer processing.**

Symptom: downstream state machine receives events out of sequence (order placed AFTER order shipped), causing incorrect state transitions or data corruption. Diagnosis: correlate event timestamps with processing timestamps; check whether related events (same entity ID) are spread across multiple partitions. Fix: use consistent key-based routing to pin all events for the same entity to the same partition; use a single-threaded consumer per entity key if ordering matters within the entity lifecycle.

**Failure Mode 3: Ghost consumer - consumer group connected but not processing.**

Symptom: consumer group shows members connected but lag grows; active heartbeats sent but no offset progress. Diagnosis: check consumer `poll.interval.ms` vs actual processing time - if processing exceeds `max.poll.interval.ms`, the broker considers the consumer dead and triggers rebalance, re-assigning the partition; the consumer rebalances, gets the same partition, processes slowly again, and the cycle repeats. Fix: reduce `max.poll.records` to process fewer messages per poll cycle, or move heavy processing to a separate thread pool while the main thread continues polling.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [MECHANISM] A consumer is processing messages from a Kafka topic but getting the same message processed multiple times. Why?**

Kafka provides at-least-once delivery by default. A consumer
processes a message, then crashes before committing the offset.
On restart, it reads the same message again (offset was not advanced).
Root cause: either the consumer is not committing offsets reliably,
or it commits after processing but the commit fails. Fix: (1) consumers
must be idempotent - process the same message twice produces the same
result. Use a unique event ID to detect and skip duplicates:
`INSERT INTO processed_events (event_id) ON CONFLICT DO NOTHING`.
(2) Alternatively, use transactional producers and the Kafka transactions
API for exactly-once semantics within the Kafka ecosystem (does not
cover external effects like database writes).

**[JUNIOR] Q2 - [MECHANISM] Consumer lag on a Kafka topic has been growing for 2 hours. Messages are accumulating. What happened?**

Consumer lag growing = consumers not keeping up with producers.
Possible causes: (1) consumer is too slow (processing bottleneck -
N+1 DB queries, slow external call). (2) consumer is failing and
retrying (check DLQ for failed messages). (3) producer rate spiked
(e.g., batch job publishing events). (4) consumers are down (check
consumer health). Diagnosis: `kafka-consumer-groups.sh --describe`
shows lag per partition. Check consumer application logs for errors.
Check processing time histogram. Fix: scale consumers horizontally
(more instances = more partition readers) up to the number of partitions.
If processing is the bottleneck: batch processing, async processing,
or optimize the slow step.

#### Candidate Mistakes

**[JUNIOR] Q3 - [MECHANISM] How do you ensure that a downstream service has processed an event before you return a response to the user?**

**What NOT to say:** "Just wait for the consumer to finish before
returning."

**Say instead:** "If you need to wait for downstream processing to
confirm before responding, the operation should be synchronous, not
event-driven. Event-driven means the publisher does not wait.
If you truly need confirmation: use request-reply messaging pattern
(publish a request event, subscribe to a reply event with a
correlation ID, wait for the reply with a timeout). Alternatively,
use a saga with explicit status polling (publish the event, return
an 'in progress' response, let the client poll for completion).
The design question is: does the user actually need to wait for
this, or can they receive a 'submitted' confirmation and be notified
asynchronously?"

#### Questions to Ask the Interviewer

**[MID] Q4 - [MECHANISM] "How do you monitor consumer lag and alert on it?"**

*Why:* Consumer lag is the key health metric for event-driven systems.
Lack of monitoring = silent failures.

**[MID] Q5 - [MECHANISM] "Do consumers need to be idempotent, and is that enforced today?"**

*Why:* Most async systems have at-least-once delivery. Idempotency
is required but often overlooked.

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



