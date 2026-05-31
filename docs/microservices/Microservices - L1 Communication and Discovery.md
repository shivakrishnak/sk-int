---
layout: default
title: "Microservices - L1 Communication and Discovery"
parent: "Microservices"
grand_parent: "SK Interview"
nav_order: 3
permalink: /microservices/l1-communication-and-discovery/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Service Communication - Sync vs Async](#service-communication---sync-vs-async) | medium |
| 2 | [Service Discovery and Registration](#service-discovery-and-registration) | medium |
| 3 | [Health Checks and Readiness Probes](#health-checks-and-readiness-probes) | medium |

---

# Service Communication - Sync vs Async

---

### 🎯 Model Answer

**30 seconds:**
> Services communicate either synchronously (the caller waits for the result) or asynchronously (the caller sends a message and continues). Synchronous communication (REST, gRPC) is simpler and provides immediate feedback. Asynchronous communication (Kafka, queues) decouples services in time and is more resilient to downstream failures. The choice is per-interaction, not per-system: use sync when you need the result immediately and the callee must be up, use async when you can tolerate eventual consistency and need resilience.

**3 minutes:**
> The sync vs async decision directly affects your system's failure modes and scalability characteristics. Synchronous: when Service A calls Service B synchronously, A's availability is bounded by B's availability. If B has 99.9% uptime and A calls B for every request, A's effective uptime is at most 99.9%. With 5 synchronous dependencies, each at 99.9%, availability degrades multiplicatively: 99.9^5 = 99.5%. Async breaks this: A publishes a message and returns immediately. B processes later. A's availability is independent of B's. But: A can no longer get the result of B's processing synchronously. This is the fundamental trade-off. Additional dimensions: latency (sync is one round trip; async adds broker latency), ordering (async brokers can provide ordering within a partition but not across multiple consumers), and complexity (async requires message formats, retry handling, idempotency). The mental model for the decision: if a user is waiting for the result right now, use sync. If the operation can succeed now and produce effects later, use async. Payment authorization = sync (user waits). Email confirmation = async (user doesn't wait for email delivery to know the order was placed).

**Blank Mind Recovery:**
**(1) Restate:** "Sync vs async - should the caller wait for the response or not?"
**(2) Framework:** "Sync = simpler, immediate feedback, couples availability. Async = resilient, eventual, decoupled."
**(3) Decision:** "Is the user waiting for this result right now? Sync. Can it happen later? Async."

---

### 📘 Concept Explanation

**What it is:**
Synchronous communication: the caller blocks until the callee responds. REST/HTTP, gRPC. Request/response model. Both services must be available simultaneously.

Asynchronous communication: the caller sends a message to a broker and continues. Kafka, RabbitMQ, SQS. The callee consumes when available. Services are temporally decoupled.

**Communication patterns:**

```
SYNC (request-response):
  Client -> OrderService -> InventoryService
  OrderService blocks waiting for InventoryService
  InventoryService down = OrderService fails
  
  Good for: real-time queries, need result to proceed
  Bad for: long-running operations, optional side effects

ASYNC (event/message):
  Client -> OrderService (places order, returns OK)
             |
             +-- publishes OrderPlacedEvent to Kafka
             
  [later] <- FulfillmentService reads event
           <- NotificationService reads event
           
  OrderService doesn't wait for either
  Both can fail and retry independently
  
  Good for: side effects, notifications, fan-out
  Bad for: need result immediately

HYBRID (common in practice):
  Order creation: sync HTTP to validate and create
  Side effects: async events for notifications,
                fulfillment, analytics
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**When to use each:**
| Concern | Sync | Async |
|---|---|---|
| Immediate result needed | Yes | No |
| Caller availability independent of callee | No | Yes |
| Latency | One RTT | +broker latency |
| Retries | Caller responsibility | Broker + consumer |
| Fan-out (multiple consumers) | Hard (N calls) | Easy (N consumers) |
| Long-running operations | Timeout risk | Natural |

---

### 💻 Code Example

```java
// BAD: All calls synchronous - availability coupling
@Service
public class OrderService {
  public Order createOrder(OrderRequest req) {
    // If any of these fail, entire order fails:
    boolean valid = inventoryClient
        .checkAvailability(req); // HTTP call
    String paymentId = paymentClient
        .authorize(req); // HTTP call
    emailClient.sendConfirmation(req); // HTTP call
    analyticsClient.track(req); // HTTP call
    
    return orderRepo.save(new Order(req, paymentId));
  }
}
// EmailService down = order creation fails
// Analytics down = order creation fails
// Neither is required for the order to be placed
```

> **Code walkthrough:** Every downstream call is on the critical path. A transient failure in analytics or email causes the entire order to fail. This is unnecessary coupling - the order can succeed even if analytics is temporarily down.

```java
// GOOD: Sync for critical path, async for side effects
@Service
public class OrderService {
  private final InventoryClient inventoryClient;
  private final PaymentClient paymentClient;
  private final KafkaTemplate<String, Object> kafka;

  public Order createOrder(OrderRequest req) {
    // SYNC: required to proceed, need result now
    boolean available = inventoryClient
        .checkAvailability(req.getProductId(),
            req.getQuantity());
    if (!available) {
      throw new OutOfStockException();
    }
    
    // SYNC: required to confirm payment
    String authCode = paymentClient
        .authorize(req.getPaymentDetails());
    
    Order order = orderRepo.save(
        new Order(req, authCode));
    
    // ASYNC: side effects that don't need a response
    kafka.send("order-placed", order.getId(),
        new OrderPlacedEvent(order));
    // FulfillmentService, EmailService, Analytics
    // consume independently at their own pace
    // Their failure does not affect order creation
    return order;
  }
}
```

> **Code walkthrough:** Only inventory check and payment authorization are on the synchronous critical path - they must succeed for the order to be valid. Everything else (fulfillment, notification, analytics) consumes the OrderPlacedEvent asynchronously. Failure in any async consumer does not affect order creation. This is the hybrid pattern in practice.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Synchronous communication is like a phone call - you wait for the answer before moving on. REST and gRPC are synchronous. Asynchronous is like sending an email - you send it and continue; the other side responds when ready. Kafka and message queues are asynchronous. Use synchronous when you need the answer immediately. Use asynchronous for things that can happen later, like sending confirmation emails or updating analytics."

**Senior / Staff:** "The sync vs async decision is about availability coupling. Every synchronous dependency reduces your effective availability. A service with 5 sync dependencies at 99.9% each has 99.5% uptime at best. Async removes this coupling. But async adds complexity: message formats, idempotency (consumers may process a message multiple times), ordering guarantees, and dead letter queue handling. The architecture decision: map each interaction to a category. Customer-facing, real-time operations use sync. Background processing, side effects, and multi-consumer fan-out use async. Document the decision explicitly in your architecture decision records."

---

### ⚠️ Common Misconceptions

**Misconception:** "Async is always better than sync for microservices."
Reality: Async adds significant complexity: idempotency requirements, dead letter queues, consumer lag monitoring, eventual consistency handling, and message schema governance. For simple request-response interactions where both services are local and available, synchronous REST or gRPC is simpler and sufficient. Use async where its resilience and fan-out properties justify the complexity.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Synchronous call chain timeout cascade**

Symptoms: User-facing requests time out after 30 seconds. Service B is healthy but Service A is degraded. Distributed trace shows A waiting for B for 30 seconds, then B waiting for C.

Root cause: No timeouts configured on inter-service calls. One slow service makes all callers slow. Thread pools fill with blocked threads.

Diagnosis: Check if timeouts are configured on all HTTP clients. Check for thread pool saturation (actuator /metrics/executor.pool.size). A full thread pool means no new requests can be processed.

Fix: Set aggressive timeouts (1-3 seconds max) on all synchronous inter-service calls. Add circuit breakers to fail fast when a service is consistently slow.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Comparison | 3 min | 2 |
| Scenario | 5 min | 2 |
| Debugging | 3 min | 1 |
| Misconception | 2 min | 1 |

#### Q1 - "Calculate the availability impact of 3 synchronous dependencies at 99.9% uptime each."
> "0.999 * 0.999 * 0.999 = 0.997. The calling service has at best 99.7% availability if it makes synchronous calls to all three. Each 'nine' of availability removes 0.1% (about 8.7 hours/year). With 3 dependencies, you lose about 26 hours/year. With async: the calling service's availability is independent of the consumers - the caller only depends on the broker's availability, which is typically higher (99.99%+) and shared."

*What separates good from great:* "The calculation assumes failures are independent. In practice, failures can be correlated (shared infrastructure, shared database, common code path). Correlated failures make the availability impact worse than the independent multiplication suggests."

---

#### Q2 - "When would you choose gRPC over REST for internal service communication?"
> "gRPC advantages: binary serialization (3-10x faster for the same payload), strongly typed contracts via Protobuf (compile-time type safety across services), native bi-directional streaming, and efficient code generation. Choose gRPC when: performance is critical (high call frequency, latency-sensitive), services are in multiple languages (Protobuf generates clients for all languages), or streaming is needed (real-time updates from server to client). Choose REST when: services need to be called by browsers or mobile apps directly (gRPC requires special proxy for browser support), the team is more familiar with REST, or the API is public-facing and needs broad compatibility."

*What separates good from great:* "gRPC's type safety is its strongest advantage at scale. A field type change in a Protobuf message is a compile error. The same change in a JSON REST API is a runtime deserialization error that may manifest as null values or exceptions. For large microservices ecosystems with many services, compile-time contract enforcement prevents a class of production incidents."

---

#### Q3 - "Design the communication pattern for an order service that needs to: check inventory, authorize payment, send confirmation email, and update analytics."
> "Sync for critical path: inventory check (must succeed to place order) and payment authorization (must succeed to confirm order) are synchronous gRPC calls with 2-second timeouts and circuit breakers. Async for side effects: confirmation email and analytics update are published as events to Kafka after the order is saved. OrderService publishes OrderPlacedEvent. EmailService and AnalyticsService consume independently. Failure in either does not affect order creation. Dead letter queues handle persistent failures. Idempotency keys in both consumers handle duplicate event delivery."

*What separates good from great:* "Add the transactional outbox pattern for the Kafka publish: write the OrderPlacedEvent to an outbox table in the same database transaction as saving the order. A relay process reads the outbox and publishes to Kafka. This ensures the event is always published if the order is saved, even if the direct Kafka publish fails."

---

#### Q4 - "What is the saga pattern and when is it needed?"
> "The Saga pattern is a sequence of local transactions where each step publishes an event or message that triggers the next step. If any step fails, compensating transactions undo the previous steps. Used for: long-running business processes that span multiple services where a global ACID transaction is not possible. Example: order fulfillment saga: (1) OrderService creates order, publishes OrderCreated. (2) InventoryService reserves stock, publishes StockReserved. (3) PaymentService charges card, publishes PaymentProcessed. (4) FulfillmentService begins shipping. If PaymentService fails: compensating transactions run in reverse: cancel stock reservation (publish StockReservationCancelled), cancel order (OrderService processes). Two implementations: choreography (each service reacts to events and publishes next) or orchestration (a Saga orchestrator service coordinates the workflow)."

*What separates good from great:* "The hardest part of Saga implementation: compensating transactions must be idempotent and must always succeed. If 'cancel stock reservation' can fail, the saga is stuck in a partially-completed state. Design compensating transactions to be retryable and to succeed even if the original operation was never applied (handle the 'reserve that never happened' case gracefully)."

---

#### Q5 - "How do you handle partial failures in synchronous service calls?"
> "Patterns for partial failure resilience: timeout (fail fast rather than wait forever - set 1-3 second timeouts on all outgoing calls), circuit breaker (after N consecutive failures to a service, stop calling it for a period and return a cached response or error - this prevents cascade failures), retry with exponential backoff (automatically retry transient failures, backing off to avoid overloading a recovering service), and fallback (when the downstream service is unavailable, return a degraded but valid response: show cached data, show a generic message, or degrade the feature gracefully). Resilience4j implements all four patterns for Spring Boot services."

*What separates good from great:* "The circuit breaker's half-open state is critical: after the break period, the circuit allows one probe request through. If it succeeds, the circuit closes and normal traffic resumes. If it fails, the circuit stays open. This auto-recovery prevents human intervention for transient outages. Tune the threshold carefully: too sensitive and the circuit trips on normal traffic spikes; too lenient and it doesn't protect against real failures."

---

#### Q6 - "What is backpressure and how does it apply to async communication?"**
> "Backpressure is the mechanism by which a consumer signals to a producer that it is overwhelmed and the producer should slow down. In async messaging with Kafka: the consumer does not apply explicit backpressure to the producer (Kafka's model is producer-broker-consumer, not direct). The broker buffers. Consumer lag grows when the consumer is slower than the producer. The practical backpressure in Kafka: monitor consumer group lag. When lag grows beyond a threshold, scale consumer instances. If lag is unbounded (consumer is permanently slower than producer), you have a capacity planning problem. True reactive streams (Project Reactor Flux) do implement backpressure within a JVM process - downstream operators can signal they are not ready, and upstream operators slow down. This applies to in-process reactive pipelines, not cross-service Kafka consumers."

*What separates good from great:* "Backpressure-aware design for Kafka consumers: when a consumer is overloaded (external database slow, downstream API slow), pause the Kafka consumer partition assignment temporarily (pause the listener) rather than letting messages queue in memory. Resume when the overload clears. This is explicit backpressure from consumer to the broker's partition assignment."

---

#### Q7 - "How do you handle idempotency in async message processing?"
> "Idempotency means processing the same message multiple times produces the same result as processing it once. Required for at-least-once delivery (Kafka default). Implementation: use the event's ID as an idempotency key. Before processing, check if this ID has been processed before (lookup in a processed_events table or Redis cache). If found: return the cached result or skip. If not found: process and record the ID. For database writes: use INSERT ... ON CONFLICT DO NOTHING (Postgres) with the event ID as a unique key. For payment processing: the payment gateway transaction ID serves as the idempotency key - the gateway rejects duplicate transactions with the same key. Design principle: idempotency is a consumer responsibility, not a producer responsibility. Producers may publish duplicate events (retries). Consumers must handle them gracefully."

*What separates good from great:* "The idempotency window matters. If you check for duplicate event IDs for 7 days and your Kafka retention is 30 days, a consumer that resets its offset to 20 days ago will encounter events outside the idempotency window and may process them again. Set the idempotency window at least as long as your maximum expected consumer offset reset range."

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


# Service Discovery and Registration

---

### 🎯 Model Answer

**30 seconds:**
> Service discovery solves the problem of how services find each other's network addresses in a dynamic environment where services scale up and down, restart, and move to different hosts. Two patterns: client-side discovery (the caller queries a registry and selects an instance) and server-side discovery (a load balancer or proxy handles the routing). In Kubernetes, server-side discovery is built in: services register via Kubernetes Service resources, and Kubernetes DNS resolves service names to ClusterIP addresses that load-balance to healthy pods.

**3 minutes:**
> Without service discovery, services need hardcoded IP addresses. In a containerized environment where pods restart with new IP addresses on every restart, hardcoding is immediately broken. Service discovery provides a dynamic, always-current map of service locations. Client-side discovery (Eureka, Consul): services register themselves with a registry. Callers query the registry for available instances and select one (usually round-robin or least-connections). The caller implements the load balancing logic. This puts more responsibility on the client but gives more control. Server-side discovery (Kubernetes Services, AWS ALB, Nginx): a load balancer or proxy sits between callers and services. Callers always call the same virtual address. The proxy maintains the list of healthy instances and load-balances. Callers are simpler (no registry queries). Kubernetes uses server-side discovery via the Service resource: a Service has a stable ClusterIP and DNS name. Kube-proxy manages iptables rules to route connections to healthy pods. CoreDNS resolves service names to ClusterIP. This is transparent to application code - applications just use service-name, Kubernetes handles the rest.

**Blank Mind Recovery:**
**(1) Restate:** "Service discovery - how does Service A find the current address of Service B?"
**(2) Two patterns:** "Client-side: the caller asks a registry. Server-side: a proxy handles routing, caller uses a stable address."
**(3) Kubernetes:** "Kubernetes provides server-side discovery built-in via Service resources and CoreDNS."

---

### 📘 Concept Explanation

**What it is:**
Service discovery is the mechanism that allows services to find and connect to each other in a dynamic infrastructure where service instances start, stop, scale, and move. Service registration is the corresponding mechanism by which service instances announce their availability.

**Client-side vs server-side:**
```
CLIENT-SIDE DISCOVERY (Eureka, Consul):
  
  ServiceA                Registry (Eureka)
  -------                 --------
  query: "where is B?"  ->  [B-instance-1: 10.0.0.1:8080]
  select instance        <-  [B-instance-2: 10.0.0.2:8080]
  call 10.0.0.2:8080 -----> ServiceB
  
  ServiceB registers on startup:
  POST /eureka/apps/B {host: 10.0.0.2, port: 8080}
  Sends heartbeat every 30s
  Deregisters on shutdown

SERVER-SIDE DISCOVERY (Kubernetes):
  
  ServiceA -> kubernetes-dns (service-b.namespace)
           -> resolves to ClusterIP: 10.96.0.5
           -> kube-proxy routes to healthy pod
           -> ServiceB pod (any healthy instance)
  
  ServiceA code: http://service-b/api/v1/...
  No registry queries in application code
  Kubernetes handles routing transparently
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Kubernetes DNS service discovery:**
```
Full DNS name:
  service-name.namespace.svc.cluster.local
  
Short names (same namespace):
  service-name          -> resolves to ClusterIP
  service-name.namespace -> explicit namespace
  
Example:
  kubectl run test --image=alpine
  nslookup order-service
  -> 10.96.0.5 (ClusterIP)
  
  All pods in the cluster can reach:
  http://order-service/api/v1/orders
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
Kubernetes service discovery is built into the platform. In a Kubernetes-based microservices system, client-side discovery registries (Eureka) are largely redundant. The team should understand both patterns (client-side for non-Kubernetes deployments and legacy systems, server-side for Kubernetes-native).

---

### 💻 Code Example

```java
// BAD: Hardcoded service addresses
@Service
public class InventoryClient {
  // Hardcoded IP: breaks when pod restarts with
  // a new IP, or when service scales to 2 instances
  private final String baseUrl = 
      "http://10.0.0.42:8080";
  
  public boolean checkAvailability(String productId) {
    // This will fail after the pod restarts
    return restTemplate.getForObject(
        baseUrl + "/api/v1/inventory/" + productId,
        Boolean.class);
  }
}
```

> **Code walkthrough:** Hardcoded IPs are the anti-pattern that service discovery solves. Pod IPs change on every restart. Scaling to 2 instances means the second instance is never called. This code works in development and fails silently in production.

```java
// GOOD: Kubernetes service name (DNS discovery)
@Service
public class InventoryClient {
  // Uses Kubernetes Service name:
  // resolves to ClusterIP via CoreDNS
  // kube-proxy load-balances to healthy pods
  private final String baseUrl = 
      "http://inventory-service";
  
  public boolean checkAvailability(String productId,
      int quantity) {
    // inventory-service resolves to the Kubernetes
    // Service ClusterIP regardless of how many pods
    // are running or what their IPs are
    return restTemplate.getForObject(
        baseUrl + "/api/v1/inventory/"
            + productId + "/available/"
            + quantity,
        Boolean.class);
  }
}

// Configuration (application.yml):
// clients:
//   inventory-service:
//     url: http://inventory-service
//     connect-timeout: 2000
//     read-timeout: 3000
// URL from config allows environment-specific override
```

> **Code walkthrough:** Using the Kubernetes Service name (inventory-service) instead of an IP address leverages built-in DNS service discovery. The Service name is stable regardless of pod restarts, scaling, or rescheduling. CoreDNS resolves it to the ClusterIP. kube-proxy load-balances across all healthy pods. The application code has no discovery logic - it just uses the hostname.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Service discovery lets services find each other by name instead of hardcoded addresses. When you run services in containers, their IP addresses change every time they restart. Service discovery solves this by giving each service a stable name. In Kubernetes, you just use the service name as the hostname, and Kubernetes DNS resolves it to the right address. Other tools like Eureka or Consul work similarly - services register their address, and callers look up the address by name."

**Senior / Staff:** "In Kubernetes environments, the built-in DNS service discovery eliminates the need for a separate service registry like Eureka for internal service-to-service communication. The platform handles it. Where client-side discovery still matters: hybrid environments (some services on Kubernetes, some on VMs), cross-cluster service discovery, service mesh configurations where services need to select specific instances (e.g., prefer same-zone instances for lower latency). Understanding both patterns is important for environments that are not purely Kubernetes-native."

---

### ⚠️ Common Misconceptions

**Misconception:** "Service discovery is only needed for microservices."
Reality: Service discovery is needed for any distributed application where service locations are dynamic. Even a two-service system benefits from discovery if services are containerized and scale. A monolith connecting to a database cluster uses a connection string that abstracts the cluster's member addresses - this is a form of service discovery.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stale service registry causes calls to dead instances**

Symptoms (with client-side discovery): service calls fail with connection refused on some percentage of requests. Other requests succeed. The failure rate matches the percentage of dead instances in the registry.

Root cause: A service instance crashed or was terminated without deregistering. The registry still shows it as healthy. Callers get routed to the dead instance.

Diagnosis: Query the service registry for the failing service. Compare registered instances to actually running pods/containers.

Fix: Ensure deregistration happens on SIGTERM (graceful shutdown hook). Configure health check-based removal: registry removes instances that fail N consecutive health checks. Implement client-side retry on connection failure: if the selected instance is unreachable, retry with a different instance.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Comparison | 3 min | 1 |
| Debugging | 3 min | 1 |
| Scenario | 3 min | 1 |

#### Q1 - "How does Kubernetes kube-proxy implement load balancing for services?"
> "kube-proxy runs on every node and manages iptables (or IPVS) rules that implement the Service's ClusterIP. When a new Service is created, kube-proxy adds iptables rules that DNAT (destination NAT) packets destined for the ClusterIP to one of the backing pod IPs. The selection is random by default (probability-based DNAT rules). iptables mode is the default. IPVS mode (enabled separately) supports more sophisticated load balancing algorithms (round-robin, least connections, source-hash). Limitation of iptables mode: load balancing is random, not connection-aware. Short-lived connections are well-balanced. Long-lived connections (persistent HTTP/2 or gRPC connections) may be poorly balanced because new connections are not created frequently."

*What separates good from great:* "gRPC uses HTTP/2 multiplexing - a single TCP connection is reused for many RPC calls. kube-proxy's iptables NAT balances at connection establishment, not per-call. So all gRPC calls on a single connection go to the same pod. To properly balance gRPC in Kubernetes, you need a service mesh (Istio, Linkerd) that understands HTTP/2 and can balance at the RPC level."

---

#### Q2 - "What is the difference between ClusterIP, NodePort, and LoadBalancer service types?"
> "ClusterIP: stable virtual IP reachable only within the cluster. Used for internal service-to-service communication. NodePort: exposes the service on a static port on every node's external IP. External traffic can reach the service via node-IP:node-port. Rarely used in production (exposes the node IP, no proper load balancing). LoadBalancer: provisions a cloud load balancer (AWS ALB, GCP LB) that routes external traffic to the service. Used for public-facing services. Each LoadBalancer costs money - use sparingly. Most production patterns: all internal services use ClusterIP. Public-facing services use an Ingress resource with a single LoadBalancer. Ingress routes based on host/path to multiple ClusterIP services."

*What separates good from great:* "The Ingress pattern is critical for cost management at scale. Without it, 20 public-facing services = 20 separate LoadBalancers = 20 separate cloud LB bills. With an Ingress controller (Nginx, Traefik): one LoadBalancer routes to all services based on hostname and path. Significant cost saving and simpler external DNS management."

---

#### Q3 - "How does service discovery work in a multi-cluster Kubernetes environment?"
> "Within a single cluster: Kubernetes DNS handles discovery. Across clusters: built-in Kubernetes does not provide cross-cluster service discovery. Options: service mesh federation (Istio with multi-cluster configuration: services in cluster A can call services in cluster B using extended service names), Consul with multi-datacenter: agents in each cluster register services with a shared Consul cluster. Callers query Consul for cross-cluster instances. External DNS and load balancer: publish internal services via external DNS records or cloud load balancers that route across clusters. The simplest approach for most teams: keep cross-cluster communication to a minimum and use explicit external endpoints for the small number of cross-cluster services."

*What separates good from great:* "Multi-cluster service discovery is an emerging area with no settled standard. CNCF Multi-Cluster SIG and projects like Liqo and Skupper are working on standards. For most teams, the practical advice is to minimize the need for cross-cluster service discovery by designing workloads that are self-contained within a cluster."

---

#### Q4 - "What is DNS-based service discovery vs API gateway-based discovery?"
> "DNS-based: services use each other's DNS names directly. No central routing layer. Low latency (one DNS lookup, then direct connection). Best for internal service-to-service calls. API gateway-based: all calls route through a central API gateway. The gateway performs discovery internally and routes to the appropriate service. The caller only knows the gateway address. Best for external clients that should not know internal service topology. Mixing them: internal services use DNS-based discovery for low latency. External clients (browsers, mobile apps, third-party systems) use the API gateway. Never make external clients aware of internal service addresses - the gateway is the stable external interface."

*What separates good from great:* "Service mesh is a third option: discovery at the data plane level via sidecar proxies (Envoy in Istio). The sidecar intercepts all outbound calls and routes based on the service mesh control plane's discovery data. This provides DNS-like simplicity for the application while adding mesh features (mTLS, circuit breaking, traffic management). Appropriate when service mesh features are needed; adds operational complexity."

---

#### Q5 - "How do you handle service discovery during a rolling deployment?"
> "During a rolling deployment: old pods are terminating while new pods are starting. The Kubernetes Service endpoints are updated as pods become ready (readiness probe passes) and as pods terminate (removed from endpoints when SIGTERM is received and grace period begins). Potential issue: a new pod is added to service endpoints when it passes its readiness probe but before it is fully warmed up (cache not populated, JIT not triggered). Requests to the new pod may be slower than usual. Mitigation: implement pre-warming logic in the startup phase. Also: ensure terminating pods are removed from service endpoints before they stop accepting connections. Set terminationGracePeriodSeconds long enough to drain in-flight requests (typically 30-60 seconds). Use preStop lifecycle hook to add a small sleep before SIGTERM processing, allowing Kubernetes to update endpoints before the pod stops accepting connections."

*What separates good from great:* "The most common misconfiguration: setting terminationGracePeriodSeconds too short. Kubernetes removes the pod from service endpoints when SIGTERM is received, but this propagation has a delay (iptables update takes 1-5 seconds on large clusters). If the pod is already closed before endpoints are updated, new requests arriving at the old iptables rule fail. Solution: preStop hook with sleep(5) so the pod stays alive long enough for endpoint propagation to complete."

---

#### Q6 - "What happens to service discovery during a cluster DNS failure?"
> "CoreDNS failure causes all service-name-based communication to fail. Services that use service names (the recommended approach) cannot resolve addresses. The blast radius: any inter-service call that uses a Kubernetes service name fails. Detection: run kubectl get pods -n kube-system - CoreDNS pods will show as not running. Immediate check from inside a pod: nslookup kubernetes.default.svc.cluster.local - should return the Kubernetes API server IP. If it fails, CoreDNS is down. Recovery: scale CoreDNS back up: kubectl scale deployment coredns -n kube-system --replicas=2. For prevention: run CoreDNS with at least 2 replicas on different nodes. Set CoreDNS resource limits appropriately (OOMKill is a common failure cause). Enable DNS caching at the node level (NodeLocal DNSCache) to reduce load on CoreDNS and provide a local fallback cache."

*What separates good from great:* "NodeLocal DNSCache creates a local DNS cache on each node. Pods resolve to the node's local cache first, then CoreDNS. If CoreDNS is slow or temporarily unavailable, the local cache serves recent entries. This provides significant resilience for steady-state traffic at the cost of slightly stale DNS entries (TTL-controlled)."

---

#### Q7 - "How does service discovery integrate with health checking?"
> "Service discovery is only valuable if it maintains an accurate list of healthy instances. Discovery and health checking are tightly coupled. Kubernetes: a pod is added to service endpoints when its readiness probe passes. It is removed when the readiness probe fails or when the pod terminates. The readiness probe (HTTP GET /ready, or TCP check, or exec command) is the health check that gates service discovery. A pod can be live (liveness probe passes = not deadlocked) but not ready (readiness probe fails = temporarily unable to handle traffic, e.g., warming up or downstream dependency not available). Distinguishing live vs ready is important: a live-but-not-ready pod is not killed (liveness probe would trigger a restart), but it is removed from service discovery (readiness probe removes it from endpoints). This allows a service to temporarily stop receiving traffic without restarting."

*What separates good from great:* "The readiness probe is a powerful circuit breaker. When a service detects that its downstream dependency is unavailable (database connection failed, Kafka is unreachable), it can fail its readiness probe voluntarily. Kubernetes removes it from service endpoints - no new traffic. Existing connections drain. The upstream services see the pod as unavailable and route to healthy instances. When the dependency recovers, the readiness probe passes again and the pod receives traffic. This is graceful degradation implemented at the infrastructure level."

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


# Health Checks and Readiness Probes

---

### 🎯 Model Answer

**30 seconds:**
> Health checks tell Kubernetes and other orchestration systems whether a service instance is functioning correctly. Kubernetes uses two probes: liveness (is the service alive and not deadlocked - if it fails, restart the pod) and readiness (is the service ready to receive traffic - if it fails, remove it from the load balancer without restarting). A third probe, startup, prevents premature liveness failures during slow startup. Correct probe configuration is essential - a misconfigured probe can cause unnecessary restarts or send traffic to a service that is not ready.

**3 minutes:**
> The distinction between liveness and readiness has significant operational implications. Liveness: detects fatal failures - the service is deadlocked, in an infinite loop, or in a state it cannot recover from without a restart. A failed liveness probe triggers a pod restart (potentially with backoff). This should only be used for genuinely unrecoverable states. Readiness: detects temporary unavailability - the service is still live but cannot handle traffic right now (warming up, downstream dependency down, cache miss flood). A failed readiness probe removes the pod from the load balancer without restarting. This is the key: you can take a pod temporarily out of service without killing it. The startup probe prevents both probes from running until the application has had enough time to start. Without it, a slow-starting application (JVM with a large class load time) would be killed by liveness probe during startup. Production checklist: readiness probe should check actual service readiness (can it serve requests?), not just that the process is running. A readiness probe that only returns 200 from a trivial endpoint does not verify that the downstream database is connected. Consider a deeper health check that verifies dependencies are accessible.

**Blank Mind Recovery:**
**(1) Restate:** "Health checks and probes - how Kubernetes knows when to restart a pod or remove it from traffic."
**(2) Three probes:** "Liveness = am I alive? (restart if fails). Readiness = can I take traffic? (remove from LB if fails). Startup = let me finish starting (prevents premature liveness failures)."
**(3) Rule:** "Use readiness for temporary unavailability. Use liveness only for states that require a restart to recover."

---

### 📘 Concept Explanation

**What it is:**
Kubernetes health probes are HTTP, TCP, or command-based checks that determine a pod's operational status. They drive two different actions: pod restarts (liveness/startup) and service endpoint management (readiness).

**Three probe types:**
```
LIVENESS PROBE:
  Question: "Is the pod still alive?"
  Failure action: restart the pod (kubelet kills it)
  Use for: deadlocks, infinite loops,
            corrupted state requiring restart
  
  Shallow check: GET /health -> 200
  Should NOT check external dependencies
  (DB down should not restart a healthy pod)

READINESS PROBE:
  Question: "Is the pod ready to receive requests?"
  Failure action: remove from Service endpoints
  Use for: warming up, dependency temporarily down,
            high load making service unable to serve

  Deeper check: can we actually serve a request?
  MAY check critical dependencies (DB connection pool)
  
STARTUP PROBE (Kubernetes 1.16+):
  Question: "Has the pod finished starting?"
  Failure action: kill and restart pod
  While failing: liveness/readiness probes disabled
  Use for: slow-starting applications (JVM, Python)
  
  Configure: failureThreshold * periodSeconds >= 
             maximum expected startup time
  e.g.: failureThreshold=30, periodSeconds=10 = 300s max
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Health check implementation:**
```yaml
# Kubernetes deployment probe config
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5

startupProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
  # Allows up to 300 seconds for startup
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
Readiness probes are a voluntary circuit breaker. A service can fail its own readiness probe to remove itself from load balancing when it detects it cannot serve traffic correctly. This is graceful degradation at the infrastructure level.

---

### 💻 Code Example

```java
// Spring Boot Actuator health endpoints
// application.yml:
// management:
//   health:
//     livenessState:
//       enabled: true
//     readinessState:
//       enabled: true
//   endpoint:
//     health:
//       probes:
//         enabled: true

// SHALLOW liveness check (correct - no dependencies)
// /actuator/health/liveness: { "status": "UP" }
// Fails only if application cannot produce a response
// Does NOT check DB, cache, or external services
// A DB outage should not restart a healthy pod

// DEEPER readiness check with custom indicator
@Component
public class DatabaseReadinessIndicator 
    extends AbstractHealthIndicator {
  
  private final DataSource dataSource;
  
  @Override
  protected void doHealthCheck(
      Health.Builder builder) throws Exception {
    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement()) {
      stmt.execute("SELECT 1");
      builder.up()
          .withDetail("database", "reachable");
    } catch (Exception e) {
      // Readiness probe fails: pod removed from LB
      // Pod is NOT restarted (liveness still passes)
      builder.down()
          .withDetail("database", "unreachable")
          .withException(e);
    }
  }
}
// /actuator/health/readiness checks all readiness
// indicators including this one
```

> **Code walkthrough:** Liveness (shallow check) returns 200 if the Spring Boot application can respond at all. Readiness (deeper check) includes a database connectivity test. If the database is down: readiness fails, the pod is removed from service endpoints, no new requests arrive. But liveness passes, so the pod is not restarted. When the database recovers, the readiness check passes again and the pod receives traffic automatically.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Kubernetes health checks tell it whether to restart a pod or stop sending it traffic. Liveness probe: if it fails, restart the pod. Use it to detect deadlocks. Readiness probe: if it fails, stop sending traffic to that pod but don't restart it. Use it for startup and temporary unavailability. Spring Boot has /actuator/health endpoints that Kubernetes can use for both probes."

**Senior / Staff:** "Readiness probes are the most powerful and most misconfigured health check. I see two common mistakes: using the same endpoint for both liveness and readiness (defeats the purpose), and making the readiness probe too shallow (just returns 200 always). The correct design: liveness is a minimal check that only fails for truly unrecoverable states. Readiness is a deeper check that verifies the service can actually handle requests - database connection pool healthy, critical upstream APIs reachable, in-memory cache populated. When a critical dependency degrades, the readiness probe fails voluntarily, removing the pod from load balancing until recovery. This is graceful degradation at the infrastructure level without requiring application-level circuit breakers."

---

### ⚠️ Common Misconceptions

**Misconception:** "A failed liveness probe just temporarily removes the pod from traffic like readiness."
Reality: A failed liveness probe causes Kubernetes to kill and restart the pod. A failed readiness probe removes the pod from the load balancer endpoints without restarting. Mixing up the two means a pod that should be temporarily taken out of service gets restarted instead, potentially amplifying the problem (restart takes time, removes the pod from service longer).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Pods in restart loop due to aggressive liveness probe**

Symptoms: kubectl get pods shows RESTARTS count climbing for a pod. kubectl describe pod shows liveness probe failures in events.

Root cause: The liveness probe is checking a dependency (like a database) that is temporarily unavailable. Each time the dependency is down, the probe fails, Kubernetes restarts the pod, and the pod connects to the still-down dependency - another failure.

Diagnosis: kubectl describe pod {name} - check events for "Liveness probe failed". Check the probe configuration - is it checking external dependencies?

Fix: Move dependency checks to the readiness probe. Liveness probe should only check if the application process itself is healthy (can respond to HTTP). A database outage should remove the pod from traffic (readiness failure), not restart it (liveness failure).

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Debugging | 5 min | 2 |
| Scenario | 3 min | 2 |

#### Q1 - "What is the difference between liveness, readiness, and startup probes?"
> "Liveness: is the pod alive? Failure = restart. For unrecoverable states (deadlocks). Readiness: is the pod ready to receive traffic? Failure = remove from load balancer, do not restart. For temporary unavailability (warming up, dependency down). Startup: has the pod finished starting? Failure = kill and restart. Prevents liveness/readiness probes from firing until the app has started. For slow-starting apps. Use them together: startup prevents premature liveness kills, readiness manages traffic routing, liveness restarts genuinely broken pods."

*What separates good from great:* "A key behavior: when a readiness probe fails, in-flight requests already dispatched to the pod continue to be processed (the pod is not instantly cut off). Only new requests stop arriving. Configure terminationGracePeriodSeconds long enough for in-flight requests to complete before the pod is removed."

---

#### Q2 - "Design health endpoints for a Spring Boot service with a PostgreSQL database and Redis cache."
> "Two endpoints via Spring Boot Actuator: /actuator/health/liveness: returns UP if the Spring context is active. No external checks. Falls when the application is deadlocked or in a fatal error state. /actuator/health/readiness: checks PostgreSQL (DataSource.getConnection() + SELECT 1), checks Redis (RedisTemplate.ping()), checks any other required dependencies. Falls when either dependency is unreachable. Maps to Kubernetes: livenessProbe -> /actuator/health/liveness (shallow, restart on failure). readinessProbe -> /actuator/health/readiness (deep, remove from LB on failure). startupProbe -> /actuator/health/liveness with high failureThreshold (allow 5 minutes for JVM startup)."

*What separates good from great:* "Redis is a cache - a cache miss means a cache bypass, not a failure. Make the Redis health check configurable: in non-critical environments, Redis unavailability may degrade performance but not warrant removing the pod from service. Use a 'cache-required' flag: if true, Redis failure fails readiness; if false, it only logs a warning. Different environments may have different criticality."

---

#### Q3 - "A pod passes the liveness probe but users are getting errors. The readiness probe is also passing. What do you investigate?"
> "If both probes pass but users get errors, the health checks are too shallow. The readiness probe is not catching the actual failure condition. Investigation: what kind of errors are users seeing? Check application logs for error patterns. If database errors: the readiness probe is not testing the actual database code path (maybe it tests connection pool but not a query). If timeout errors: the readiness probe does not test call latency to upstream dependencies. If authentication errors: the readiness probe does not test auth service connectivity. Fix: make the readiness probe deeper - test the actual critical paths that users depend on. Consider a synthetic health check that performs a representative business operation (place a test order, search for a test product) and verify the result."

*What separates good from great:* "The synthetic health check pattern (also called canary health check): the health endpoint performs a real operation (query a known record, call a downstream API with a known test case) and verifies the result. This catches issues that a simple 'is the database connected?' check would miss (database is connected but returning corrupt data, downstream API is responding but with wrong data)."

---

#### Q4 - "How do you use readiness probes for zero-downtime deployments?"
> "Rolling deployment with readiness probes: Kubernetes deploys new pods. New pods start and run startup probe until startup completes. Then readiness probe runs. Old pods continue receiving traffic until new pods pass readiness. When new pods are ready, traffic shifts. Old pods receive SIGTERM and complete in-flight requests during grace period. No traffic is lost because new pods are proven ready before old pods are terminated. Key configuration: maxUnavailable: 0 (never take old pods down before new pods are ready), maxSurge: 1 (add one extra pod during transition). This ensures no traffic interruption. If a new pod's readiness probe fails: it never receives traffic. Kubernetes does not terminate old pods. The deployment stops (depending on minReadySeconds config). Old pods continue serving. The failed deployment is detected and can be rolled back."

*What separates good from great:* "Set minReadySeconds: a pod must be continuously ready for N seconds before it is considered stable. Without this, a pod might pass readiness briefly (flapping) and be counted as ready, leading to premature termination of old pods. minReadySeconds ensures the new pod is stable under real traffic before the rollout proceeds."

---

#### Q5 - "What is a deep health check vs a shallow health check? When should each be used?"
> "Shallow health check: tests only that the application process is responding. Returns 200 OK from any handler. Tests: is the JVM running? Is the HTTP server accepting connections? Deep health check: tests actual service readiness. Makes a database query, calls a dependency's health endpoint, checks in-memory state (is the cache populated? are required configs loaded?). Use shallow for liveness (a healthy app that cannot reach its database is still alive - don't restart it). Use deep for readiness (a pod that cannot reach its database should not receive traffic). The danger of deep liveness probes: if the probe checks an external dependency and that dependency is slow or down, all pods fail their liveness probes simultaneously and all restart at the same time - amplifying the outage."

*What separates good from great:* "Deep readiness probes have a subtlety: they add latency to the probe check. If the readiness probe takes 3 seconds (slow database), and the probe timeoutSeconds is 1 second, the probe times out and fails - not because the service is unhealthy but because the probe is too slow. Tune timeoutSeconds appropriately, or use async health state: a background goroutine/thread polls dependencies and updates a flag; the readiness endpoint reads the flag rather than making a live call."

---

#### Q6 - "How do health checks interact with autoscaling?"
> "Kubernetes Horizontal Pod Autoscaler (HPA) scales based on CPU, memory, or custom metrics - not health probes. However, health probes affect autoscaling indirectly: if readiness probes fail on some pods (causing them to leave the load balancer), those pods still count toward the total pod count for scaling calculations. If you want failed-readiness pods to not count, you need to track ready pod count as a custom metric. More importantly: if a service is under high load causing CPU to spike, the HPA adds pods. Those new pods must pass startup + readiness probes before they receive traffic. If startup is slow (5 minutes), the HPA has added pods but they are not helping yet. Design fast startups for horizontally-scaled services: pre-warm caches in the background after readiness passes (not before - passing readiness with a cold cache is acceptable, serving cold-cache requests is expected)."

*What separates good from great:* "Pod Disruption Budget (PDB) interacts with health checks: a PDB specifies the minimum number of ready pods that must be available during voluntary disruptions (node maintenance, deployments). If a readiness probe is misconfigured and causes frequent false failures, the PDB may prevent the cluster from performing node maintenance because not enough pods are continuously ready. Monitor continuous readiness over time, not just point-in-time readiness."

---

#### Q7 - "Write the startup probe configuration for a Java microservice that takes up to 3 minutes to start."
> "Configuration: startupProbe: httpGet: path: /actuator/health/liveness, port: 8080, failureThreshold: 36, periodSeconds: 5. Rationale: 36 * 5 = 180 seconds = 3 minutes maximum startup time. Every 5 seconds Kubernetes checks if the app has started. If it does not start within 180 seconds, Kubernetes kills and restarts the pod. Once the startup probe succeeds once, Kubernetes switches to liveness and readiness probes. Also configure the liveness probe with initialDelaySeconds: 0 (startup probe handles the delay) and the readiness probe separately. Why failureThreshold instead of initialDelaySeconds: initialDelaySeconds delays all probe checks, including after restarts. With the startup probe, subsequent restarts also go through the full startup probe window - they do not skip to liveness after initialDelaySeconds."

*What separates good from great:* "A 3-minute Java startup is a red flag. Investigate what is causing the slow startup: is it class loading (use AppCDS or CRaC to cache the class list), is it database migration (Flyway running during startup - consider running migrations as a separate init container), or is it cache warming (move cache warm to background after readiness passes). Slow startup means slow recovery from crashes and slow scale-out. Target under 30 seconds for production Java microservices."

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



